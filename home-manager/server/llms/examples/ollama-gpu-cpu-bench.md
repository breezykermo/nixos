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

Results from the run this harness was written for live in
`/etc/nixos/docs/strix-halo-igpu-vs-cpu-bench.md` — full tables, method, and caveats. The
headline, on gfx1151 (Ryzen AI Max+ 395, 128 GB LPDDR5X, kernel 6.18.39, ollama 0.32.1):

| model | prefill GPU:CPU | gen GPU:CPU | gen GPU tok/s | achieved GPU GB/s |
|---|---|---|---|---|
| qwen3-coder:30b (A3B, Q4_K_M) | 6.09× | 2.64× | 59.2 | 119 (46% of bus) |
| qwen3.6:35b (Q4_K_M) | 4.80× | 1.91× | 54.7 | 80 (31%) |
| gpt-oss:120b (A5.1B, MXFP4) | 4.15× | 1.89× | 32.5 | 93 (36%) |
| GLM-4.5-Air (A12B, Q5_K_M) | CPU-only — will not load at 48/48 layers | | 7.1 on CPU | 65 on CPU (25%) |

The shape to expect on any shared-memory APU: **prefill favours the GPU by 4–6×,
generation by only ~2×**, because CPU and iGPU contend for the same LPDDR5X. Generation is
bandwidth-bound, so the GPU's decode advantage is just the gap between what the iGPU can
pull (31–46% of 256 GB/s) and what the CPU cores can (16–25%) — not a compute gap. If a
run reports a *large* generation ratio, distrust it before celebrating: the usual cause is
one of the four traps below.

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

   **The warm-up counts as a request.** This bit me on the first real run: the warm-up
   used offset 0 and so did rep 0, so rep 0 was reading its own warm-up's cache and
   reported **253,822 tok/s** prefill against a true 1,255 — a number absurd enough to
   notice, which is the only reason it did not quietly poison the table. Hence
   `WARM_OFFSET`, held deliberately outside `OFFSETS`. Sanity rule: within a cell the
   three reps should agree within a few percent; any rep that is orders of magnitude
   faster than its siblings is a cache hit, not a result.
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

**Order the cells so the dangerous one runs last.** On gfx1151 a large enough full
offload (~76 GiB of buffers, GLM-4.5-Air:Q5_K_M) trips an amdgpu KFD SVM vs `kcompactd`
lock inversion: `llama-server` wedges unkillably in D state right after `offloaded N/N
layers`, the GTT is never freed, and only a reboot recovers. A wedge in the middle of the
matrix costs every cell you had not reached yet, so the script builds an explicit `CELLS`
list with the risky pair appended at the end rather than iterating the plain
`MODELS x MODES` product. `sudo sysctl vm.compaction_proactiveness=0` is the runtime
mitigation worth trying first. Results are appended to `results.jsonl` after each cell,
so a wedge keeps everything already measured.
