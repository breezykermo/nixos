# Next prompt: benchmark iGPU vs CPU after reboot

Hand this to a fresh Claude session on `homework` once the box has rebooted into the
new kernel params. It is written to be self-contained — a fresh session has none of
the context from the session that produced it.

---

This is a NixOS box (/etc/nixos, machine "homework"): Framework Desktop, Ryzen AI
Max+ 395 "Strix Halo", 128GB RAM, Radeon 8060S iGPU (gfx1151), ollama 0.32.1 via
pkgs.ollama-rocm on 127.0.0.1:11434.

We just rebooted into new kernel params that raise the amdgpu GTT ceiling from
62.5 GiB to 110 GiB (amdgpu.gttsize=112640, ttm.pages_limit=28835840). Before this,
ollama silently ran CPU-only, and large models hung on load. Read the long comment
blocks in machines/homework/configuration.nix first — they document the whole
diagnosis and are the context you need.

TASK 1 — verify the reboot took:
  cat /proc/cmdline                                  # both params present
  cat /sys/module/ttm/parameters/pages_limit         # want 28835840, not 16395667
  journalctl -u ollama -b | grep wait-for-kfd        # which branch fired this boot
  journalctl -u ollama -b | grep 'inference compute' # want library=ROCm compute=gfx1151
If wait-for-kfd says "already present at unit start", note it — several consecutive
COLD boots saying that means the ExecStartPre workaround can be removed.

TASK 2 — the load that has never succeeded on this machine:
gpt-oss:120b at full offload (37/37 layers) previously hung forever against the old
ceiling. Load it now and confirm it completes and reports "100% GPU" in `ollama ps`.
Then do the same for MichelRosselli/GLM-4.5-Air:Q5_K_M (~83GB, needs ~85 GiB GTT).
These are the two loads the whole kernel-param change exists for.

TASK 3 — benchmark iGPU vs CPU, for each of:
  qwen3-coder:30b, qwen3.6:35b, gpt-oss:120b, MichelRosselli/GLM-4.5-Air:Q5_K_M

Force CPU with "options":{"num_gpu":0}; GPU is the default. Pull timings from the
/api/generate JSON: prompt_eval_count/prompt_eval_duration (prefill) and
eval_count/eval_duration (generation), durations in ns.

Method that matters here:
- Use a LONG prompt (>=4000 tokens) for prefill numbers. A short prompt gives pure
  noise — an earlier 21-token measurement was meaningless.
- Warm the model first with a throwaway request, then measure; don't time a load.
- 3 reps per cell, report median, and note spread.
- Confirm "100% GPU" / "100% CPU" in `ollama ps` per cell — a silent partial offload
  would invalidate the comparison.
- Watch the iGPU with nvtop (reads sysfs). btop and amdsmi are blind on this iGPU.

TASK 4 — the actual question:
CPU and iGPU share one LPDDR5X bus (~256 GB/s theoretical), so the GPU's advantage
should be large on prefill (compute-bound) and much smaller on generation
(bandwidth-bound). Test that. Report tok/s per model per mode, the GPU:CPU ratio for
prefill vs generation separately, and say plainly whether the data supports it.
Also measure achieved memory bandwidth (bytes of active weights x tok/s) against the
256 GB/s ceiling to see how close generation actually gets.

Known traps:
- OLLAMA_LOAD_TIMEOUT is 5m; a cold 61GB load can exceed it. If a load fails with
  "timed out waiting for llama-server to start", that's the timeout, not a hang.
- The real hang signature is different: stuck AFTER "load_tensors: offloaded N/N
  layers to GPU" with one thread at ~90% CPU, GPU 0% busy, zero disk I/O. That means
  the GTT ceiling was hit. Check the projected size in the
  common_memory_breakdown_print log lines against pages_limit x 4KiB.
- Ollama cannot see the GTT cap — it sizes against free system RAM and will happily
  over-commit. Two big models resident at once can exceed 110 GiB (GLM + gpt-oss is
  ~152 GiB). Unload between models: "keep_alive":0.
- GLM-4.5-Air on CPU (num_gpu:0) will be slow. Let it run — that cell is the point of
  the comparison, not a hang.
- Do NOT run `just deploy` — the user always deploys manually.
- Use jj, never git.

Deliverable: a table of tok/s (prefill and generation, GPU and CPU, per model), the
ratios, and a short verdict on when the iGPU is worth it on this hardware.

---

## Baseline already measured (pre-reboot, old 62.5 GiB ceiling)

For comparison when the new numbers come in:

| measurement | value |
|---|---|
| qwen3-coder:30b generation, 100% GPU | 67.5 tok/s |
| qwen3-coder:30b resident @ 32k / 128k / 256k | 21GB / 32GB / 45GB, all 100% GPU |
| gpt-oss:120b KV+compute @ 32k / 128k | 1437 MiB / 5557 MiB |
| gpt-oss:120b weights | 61223 MiB |
| gpt-oss:120b at 28/37 layers (56 GiB GTT) | loaded + generated in 41s |
| gpt-oss:120b at 37/37 layers (62.6 GiB GTT) | hung indefinitely — the bug this fixes |
| NVMe sequential read | 6.0 GB/s (never the bottleneck) |

No prefill baseline worth quoting — the only one taken used a 21-token prompt.
