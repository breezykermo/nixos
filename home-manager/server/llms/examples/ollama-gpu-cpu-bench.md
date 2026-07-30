---
title: Benchmark ollama iGPU vs CPU honestly
when: You want prefill and generation tok/s for a local model, GPU vs CPU, and you need the numbers to actually mean something
tags: [ollama, benchmark, rocm, gfx1151, llm]
---

```bash
# Runs every (model x {gpu,cpu}) cell, 3 reps each, writes results.jsonl.
python3 /etc/nixos/home-manager/server/llms/examples/ollama-gpu-cpu-bench.py ~/ollama-bench

# GPU is ollama's default; CPU is forced per-request, no restart needed:
curl -s localhost:11434/api/generate \
  -d '{"model":"qwen3-coder:30b","prompt":"...","stream":false,"options":{"num_gpu":0}}'

# Timings come out of the response JSON, all durations in nanoseconds:
#   prompt_eval_count / prompt_eval_duration  -> prefill tok/s
#   eval_count        / eval_duration         -> generation tok/s
```

Notes — four traps, each of which silently produces a plausible-looking wrong number:

1. **Short prompts measure nothing.** Prefill on a 21-token prompt is pure noise; the
   per-request fixed costs dwarf the actual matmuls. Use ≥4000 tokens. The script slices
   18000 chars of real prose (~4.5k tokens) out of files in this repo — synthetic filler
   like `"word " * 5000` tokenizes unrealistically and inflates throughput.
2. **Identical prompts hit the KV prefix cache.** llama.cpp reuses the cached prefix
   across requests in a slot, so rep 2 reports `prompt_eval_count` near 0 and a
   ludicrous prefill rate. The script starts each rep at a *different* corpus offset so
   the token stream diverges at position 0. Varying only the *end* of the prompt does
   not work — the cache matches on prefix.
3. **Never time a cold load.** `load_duration` is disk plus GTT transfer, tens of
   seconds on a 60GB model, and it lands inside `total_duration`. Warm the model with a
   throwaway request first, then measure.
4. **Verify the processor split per cell.** `ollama ps` must read `100% GPU` or
   `100% CPU`. A silent partial offload turns the comparison into a blend of both and
   the ratio becomes meaningless.

Watch the GPU with `nvtop` (reads sysfs). `btop` and `amdsmi` are blind on this iGPU.
Raw counters: `/sys/class/drm/card1/device/{gpu_busy_percent,mem_info_gtt_used}`.

Unload between cells (`"keep_alive": 0`) — ollama sizes loads against free system RAM,
cannot see the GTT cap, and will happily over-commit if two large models are resident.
