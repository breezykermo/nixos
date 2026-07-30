# iGPU vs CPU inference on Strix Halo (homework, 2026-07-30)

Framework Desktop, Ryzen AI Max+ 395, 128 GB LPDDR5X, Radeon 8060S (gfx1151), kernel
6.18.39, ollama 0.32.1 (`pkgs.ollama-rocm`), GTT ceiling raised to 110 GiB.

Method: `home-manager/server/llms/examples/ollama-gpu-cpu-bench.py`, 3 reps per cell,
`num_ctx=8192`, `num_predict=128`, ~4.5k-token prompt sliced from real prose at a distinct
offset per rep (defeats the KV prefix cache), warm-up at a further distinct offset, model
unloaded between cells, `ollama ps` verified `100% GPU` / `100% CPU` on every cell.
Raw data: `~/ollama-bench/results.jsonl` (machine-local); recompute with the sibling
`analyze.py`. The harness and the four ways a benchmark like this lies to you are
documented in the hoard: `home-manager/server/llms/examples/ollama-gpu-cpu-bench.md`.

## Throughput

| model | prefill GPU | prefill CPU | prefill GPU:CPU | gen GPU | gen CPU | gen GPU:CPU |
|---|---|---|---|---|---|---|
| qwen3-coder:30b (A3B, Q4_K_M) | 1261.4 | 207.0 | **6.09×** | 59.2 | 22.4 | **2.64×** |
| qwen3.6:35b (A~2.2B, Q4_K_M) | 1046.2 | 217.9 | **4.80×** | 54.7 | 28.7 | **1.91×** |
| gpt-oss:120b (A5.1B, MXFP4) | 680.2 | 163.7 | **4.15×** | 32.5 | 17.2 | **1.89×** |
| GLM-4.5-Air:Q5_K_M (A12B) | — | 33.0 | — | — | 7.1 | — |

All figures tok/s, mean of 3 reps. Rep-to-rep spread was under 2% everywhere except
qwen3-coder CPU generation (20.3–23.7), so single-digit differences are not meaningful.

Cold load time, for scale: qwen3-coder 6.1 s GPU / 29.5 s CPU, qwen3.6 12.1 / 30.2,
gpt-oss:120b 153.6 / 50.1, GLM-4.5-Air — / 161.2. Note gpt-oss loads *slower* onto the
GPU than the CPU: the GTT transfer of 61 GiB of weights costs more than mmap'ing them.

## The hypothesis, tested

The claim was that because CPU and iGPU share one LPDDR5X bus (~256 GB/s theoretical),
the GPU's advantage should be large on prefill (compute-bound) and much smaller on
generation (bandwidth-bound). **The data supports it, unambiguously and with no
exceptions.** Prefill ratios cluster at 4.2–6.1×; generation ratios at 1.9–2.6×. Every
model shows the prefill ratio at roughly 2.3–2.9× its own generation ratio, so the effect
is a property of the platform rather than of any one model.

## Achieved memory bandwidth on generation

Bytes per generated token = active params × (file bytes ÷ total params), i.e. the file's
average bytes-per-parameter applied to the *active* parameter count, since an MoE only
streams the experts it routes to. KV-cache traffic is on top of this and ignored (small at
4.5k context), so these are floors.

| model | active params | bytes/token | GPU GB/s | % of 256 | CPU GB/s | % of 256 |
|---|---|---|---|---|---|---|
| qwen3-coder:30b | 3.3 B | 2.01 GB | 118.8 | 46.4% | 45.0 | 17.6% |
| qwen3.6:35b | ~2.2 B | 1.46 GB | 80.1 | 31.3% | 42.0 | 16.4% |
| gpt-oss:120b | 5.1 B | 2.85 GB | 92.7 | 36.2% | 49.0 | 19.1% |
| GLM-4.5-Air | 12 B | 9.06 GB | — | — | 64.6 | 25.2% |

Two things fall out. **The iGPU reaches 31–46% of the theoretical bus** on generation —
respectable for LPDDR5X with real access patterns, and it explains why the generation
ratio is only ~2×: the GPU is not compute-starved there, it is waiting on the same memory
the CPU waits on. **The CPU saturates at 42–65 GB/s**, roughly 16–25% of the bus, which is
about what 16 Zen 5 cores can pull; that ceiling, not arithmetic, is what caps CPU
generation. The gap between the two — ~2× — *is* the generation ratio.

Qwen3.6's active-parameter count (2.2 B) is derived from GGUF metadata rather than a
published A-number, so its bandwidth row carries more uncertainty than the others; its
`head_count_kv` is absent from the metadata entirely.

## GLM-4.5-Air at full offload: still not usable, but the failure changed

Cell run last, deliberately, with `vm.compaction_proactiveness=0` applied beforehand.
Outcome: **no deadlock.** The load allocated 76,486 MiB of ROCm buffers, reached
`offloaded 48/48 layers to GPU`, then sat there with `llama-server` in **R** state at 55%
CPU and `gpu_busy_percent` at 0–5% until ollama's 5-minute `OLLAMA_LOAD_TIMEOUT` killed it.
The kill worked, GTT dropped from 77 GiB back to 365 MiB, memory returned to 121 GiB
available, and `journalctl -k` recorded **zero** `blocked for more than` warnings —
hung-task detection fires at 120 s in D state, so nothing was ever wedged.

That is a materially better failure than the pre-reboot one, which put `llama-server` in
unkillable D state with 78 GiB of GTT stranded and needed a reboot. Turning off proactive
compaction appears to have removed the lock inversion. What remains is something slow
rather than something stuck, in a phase after tensor load that produces no log output and
barely touches the GPU. Whether a longer timeout finishes it is untested.

**Practical verdict for GLM-4.5-Air:** unusable at 48/48 layers as configured. Either cap
it (`"options": {"num_gpu": <layers>}`) or run it on CPU at 7.1 tok/s. It is the one model
here where the CPU path is not merely slower but is the only path.

## When is the iGPU worth it here?

- **Always for prefill.** 4–6× is the difference between a 4.5k-token prompt taking 4 s
  and taking 22 s, and agentic workloads re-read large contexts constantly. This is the
  whole reason to care about the iGPU on this box.
- **Modestly for generation.** ~2×. Real, worth having, not transformative — and it is
  bandwidth, not compute, that sets the limit.
- **Not for one-shot use of a very large model.** gpt-oss:120b costs 154 s to load onto
  the GPU versus 50 s onto the CPU; at 32.5 vs 17.2 tok/s generation, the GPU only repays
  that 104 s deficit after roughly 1,800 generated tokens. Keep such models resident
  (`keep_alive`) or the load dominates.
- **Smaller MoE models win biggest.** qwen3-coder:30b posts both the best prefill ratio
  (6.09×) and the best absolute generation rate (59.2 tok/s), and loads in 6 s. For
  interactive work it is the model to reach for; gpt-oss:120b buys capability at ~55% of
  the throughput.
