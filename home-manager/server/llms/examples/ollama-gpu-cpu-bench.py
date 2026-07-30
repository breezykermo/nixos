#!/usr/bin/env python3
"""iGPU vs CPU benchmark for ollama on Strix Halo (gfx1151).

Method notes:
- Long prompt (>=4000 tok) so prefill is measured, not noise.
- Each rep uses a DIFFERENT corpus slice offset so the prompt differs from token 0,
  defeating llama.cpp's KV prefix cache (identical prompts would report ~0 prefill).
- Warm-up request per cell loads the model; timings come only from the reps.
- num_ctx pinned so GPU and CPU cells allocate identical KV.
- Model unloaded (keep_alive:0) between cells: two big models resident can blow the
  110 GiB GTT ceiling.

Usage:  ollama-gpu-cpu-bench.py [outdir]        # default outdir: ./ollama-bench
"""
import json
import os
import subprocess
import sys
import time
import urllib.request

HOST = "http://127.0.0.1:11434"
OUTDIR = sys.argv[1] if len(sys.argv) > 1 else "./ollama-bench"
OUT = os.path.join(OUTDIR, "results.jsonl")

PROMPT_CHARS = 18000          # ~4.5k tokens
OFFSETS = [0, 1500, 3000]     # 3 reps, distinct from token 0
# The warm-up slice must not coincide with any rep's slice, or that rep's prompt is a KV
# prefix-cache hit and its prefill rate comes back absurd (observed: 253,822 tok/s against
# a real 1,255 tok/s). Keep this offset out of OFFSETS.
WARM_OFFSET = 4500
NUM_PREDICT = 128
NUM_CTX = 8192

MODELS = ["qwen3-coder:30b", "qwen3.6:35b", "gpt-oss:120b",
          "MichelRosselli/GLM-4.5-Air:Q5_K_M"]
MODES = ["gpu", "cpu"]

# Explicit cell order rather than the plain MODELS x MODES product: the GLM-4.5-Air GPU
# cell can deadlock the kernel (amdgpu KFD SVM vs kcompactd lock inversion, unkillable D
# state, reboot-only recovery), so it runs dead last. A wedge there costs nothing already
# measured.
RISKY = ("MichelRosselli/GLM-4.5-Air:Q5_K_M", "gpu")
CELLS = [(m, d) for m in MODELS for d in MODES if (m, d) != RISKY] + [RISKY]

# Any long, natural prose works; these are just files that exist on this box and are
# comfortably longer than PROMPT_CHARS + max(OFFSETS). Synthetic filler would tokenize
# unrealistically, so prefer real text.
CORPUS_SOURCES = ["/etc/nixos/CLAUDE.md", "/etc/nixos/THEMING.md",
                  "/etc/nixos/machines/homework/configuration.nix"]

os.makedirs(OUTDIR, exist_ok=True)
text = "".join(open(p).read() for p in CORPUS_SOURCES if os.path.exists(p))
need = PROMPT_CHARS + max(OFFSETS + [WARM_OFFSET])
if len(text) < need:
    sys.exit(f"corpus too short: {len(text)} chars, need {need}")


def prompt_for(offset):
    body = text[offset:offset + PROMPT_CHARS]
    return ("Read the following configuration notes carefully.\n\n" + body +
            "\n\nIn one sentence, what is the single most important constraint described above?")


def post(path, payload, timeout=7200):
    req = urllib.request.Request(
        HOST + path,
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read())


def generate(model, prompt, mode, num_predict, keep_alive="5m", num_ctx=NUM_CTX):
    opts = {"num_ctx": num_ctx, "num_predict": num_predict, "temperature": 0}
    if mode == "cpu":
        opts["num_gpu"] = 0
    return post("/api/generate", {
        "model": model, "prompt": prompt, "stream": False,
        "options": opts, "keep_alive": keep_alive,
    })


def unload_all():
    """Unload only what is actually resident. Loading a model just to unload it would
    cost minutes on the 65-83GB ones, and two big models resident at once can exceed
    the 110 GiB GTT cap."""
    try:
        with urllib.request.urlopen(HOST + "/api/ps", timeout=30) as r:
            live = [m["name"] for m in json.loads(r.read()).get("models", [])]
    except Exception as e:
        log(f"    ps warn: {e}")
        return
    for m in live:
        try:
            generate(m, "x", "gpu", 1, keep_alive=0, num_ctx=512)
            log(f"    unloaded {m}")
        except Exception as e:
            log(f"    unload warn {m}: {e}")
    if live:
        time.sleep(5)


def ps():
    out = subprocess.run(["ollama", "ps"], capture_output=True, text=True).stdout
    lines = [l for l in out.splitlines()[1:] if l.strip()]
    return lines


def log(msg):
    print(msg, flush=True)


results = []
fh = open(OUT, "a")

for model, mode in CELLS:
    log(f"\n=== {model} [{mode}] ===")
    unload_all()

    t0 = time.time()
    try:
        generate(model, prompt_for(WARM_OFFSET), mode, 8)
    except Exception as e:
        log(f"  WARM FAILED after {time.time()-t0:.0f}s: {e}")
        rec = {"model": model, "mode": mode, "error": str(e),
               "warm_seconds": round(time.time() - t0, 1)}
        fh.write(json.dumps(rec) + "\n"); fh.flush()
        results.append(rec)
        continue
    warm_s = time.time() - t0
    proc = ps()
    log(f"  warm+load {warm_s:.1f}s | ollama ps: {proc}")

    reps = []
    for i, off in enumerate(OFFSETS):
        try:
            r = generate(model, prompt_for(off), mode, NUM_PREDICT)
        except Exception as e:
            log(f"  rep{i} FAILED: {e}")
            continue
        pc, pd = r.get("prompt_eval_count", 0), r.get("prompt_eval_duration", 0)
        ec, ed = r.get("eval_count", 0), r.get("eval_duration", 0)
        pre = pc / (pd / 1e9) if pd else None
        gen = ec / (ed / 1e9) if ed else None
        reps.append({"offset": off, "prompt_tokens": pc, "prefill_tok_s": pre,
                     "gen_tokens": ec, "gen_tok_s": gen,
                     "load_ns": r.get("load_duration"),
                     "total_ns": r.get("total_duration")})
        log(f"  rep{i} off={off}: prompt={pc}tok prefill={pre and round(pre,2)} tok/s"
            f" | gen={ec}tok {gen and round(gen,2)} tok/s")

    rec = {"model": model, "mode": mode, "processor": proc,
           "warm_seconds": round(warm_s, 1), "num_ctx": NUM_CTX,
           "num_predict": NUM_PREDICT, "reps": reps}
    fh.write(json.dumps(rec) + "\n"); fh.flush()
    results.append(rec)

    unload_all()

log("\nDONE")
