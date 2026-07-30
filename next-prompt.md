# Next prompt: finish the iGPU vs CPU benchmark

Hand this to a fresh Claude session on `homework` **after the box has rebooted**. Written
to be self-contained — a fresh session has none of the prior context.

Machine: NixOS (`/etc/nixos`, machine "homework"), Framework Desktop, Ryzen AI Max+ 395
"Strix Halo", 128GB RAM, Radeon 8060S iGPU (gfx1151), kernel 6.18.39, ollama 0.32.1 via
`pkgs.ollama-rocm` on 127.0.0.1:11434.

---

## What the previous session established (do not re-derive)

**The kernel-param change works.** `amdgpu.gttsize=112640` + `ttm.pages_limit=28835840`
raised the GTT ceiling from 62.5 GiB to **110 GiB**, confirmed by
`/sys/class/drm/card1/device/mem_info_gtt_total` and by ollama logging
`library=ROCm compute=gfx1151 total="110.0 GiB"`.

**`gpt-oss:120b` at full offload now works** — the load that used to hang forever.
44.7 s, `offloaded 37/37 layers`, `100% GPU`, 131072 context, 66780 MiB GTT
(61223 model + 4689 KV + 868 compute). That result is banked; no need to repeat it.

**`GLM-4.5-Air:Q5_K_M` at full offload deadlocks the kernel.** This is a *different* bug
from the GTT ceiling, and it wears the same outward disguise. The allocation succeeds —
78 GiB resident of the 110 GiB cap, `projected to use 78302 MiB`,
`ROCm0 model buffer size = 76486.61 MiB`, tensors read from disk at 1.9 GB/s — and then
it wedges immediately after `load_tensors: offloaded 48/48 layers to GPU` with no further
log output. Verified still wedged at 19 minutes on a private ollama with
`OLLAMA_LOAD_TIMEOUT=30m`, so raising the timeout is **not** the fix.

The kernel stacks (`journalctl -k -b | grep -A45 'blocked for more than'`; note
`dmesg` itself is blocked by `kernel.dmesg_restrict=1`):

```
llama-server  ioctl(/dev/kfd) → kfd_ioctl_svm → svm_range_set_attr → blocked on mutex
kcompactd0    compact_zone → svm_range_cpu_invalidate_pagetables → blocked on same mutex
both: "blocked on a mutex likely owned by task kworker/6:0:31102"
```

Memory compaction calls amdgpu's MMU-notifier invalidate callback, which wants a mutex
held against the SVM range setup llama-server is waiting on. Lock inversion. `llama-server`
lands in **D state, unkillable**, the 78 GiB of GTT is never released, and `kcompactd0`
stays stuck — which also makes `ps`/`pgrep`/`pidof` appear to hang, since they enter D
state themselves reading the wedged process's `/proc` entry. **Only a reboot recovers.**

Trigger appears to be buffer size: 61 GiB (gpt-oss) fine, 76 GiB (GLM) deadlocks.

---

## TASK A — sanity check the fresh boot

```bash
cat /sys/module/ttm/parameters/pages_limit             # want 28835840
cat /sys/class/drm/card1/device/mem_info_gtt_total     # want ~118111600640 (110 GiB)
journalctl -u ollama -b | grep -E 'wait-for-kfd|inference compute'
```

`inference compute` **must** show `library=ROCm compute=gfx1151`. If it shows
`library=cpu` / `total_vram="0 B"`, ollama's one-shot GPU probe lost the cold-boot race —
`sudo systemctl restart ollama` fixes it for the rest of the uptime (ask the user to run
that; it needs a password). This happened on the previous boot even though the
`wait-for-kfd` ExecStartPre logged success, which is a real gap: see TASK D.

## TASK B — the benchmark (the actual deliverable)

The harness is already written and validated:
`/etc/nixos/home-manager/server/llms/examples/ollama-gpu-cpu-bench.py`, documented in the
sibling `.md`. Run it, expect roughly an hour, and put its output somewhere durable
(**not** `/tmp`, which the reboot just wiped):

```bash
python3 /etc/nixos/home-manager/server/llms/examples/ollama-gpu-cpu-bench.py ~/ollama-bench
```

It covers `qwen3-coder:30b`, `qwen3.6:35b`, `gpt-oss:120b`,
`MichelRosselli/GLM-4.5-Air:Q5_K_M` × {gpu, cpu}, 3 reps per cell, `num_ctx=8192`,
`num_predict=128`, ~4.5k-token prompt, warm-up before every measured rep, and it writes
`results.jsonl` incrementally so a crash mid-run keeps the earlier cells.

**Before the GLM GPU cell, apply the agreed mitigation** — the user chose to try this:

```bash
sudo sysctl vm.compaction_proactiveness=0     # default is 20; needs the user to run it
```

`kcompactd` is literally one of the two deadlock participants, so stopping proactive
compaction targets the bug directly, and it is a runtime sysctl — revertible, no rebuild.
If GLM still wedges, **stop**: the box needs another reboot, and the honest answer is that
GLM-4.5-Air is not usable at full offload on this kernel. Report the three working models
plus GLM's CPU cell rather than burning further reboots. Run the GLM GPU cell **last** so
a wedge cannot cost you the other results.

Watch the load with `nvtop` (`btop` and `amdsmi` are blind on this iGPU). The wedge
signature to abort on: stuck after `offloaded N/N layers`, `gpu_busy_percent` 1–3%, one
thread ~88% CPU, GTT stable, no new log lines.

## TASK C — the actual question

CPU and iGPU share one LPDDR5X bus (~256 GB/s theoretical), so the GPU's advantage should
be large on prefill (compute-bound) and much smaller on generation (bandwidth-bound).
Test that. Report tok/s per model per mode, the GPU:CPU ratio for prefill and generation
**separately**, and say plainly whether the data supports the hypothesis. Also compute
achieved memory bandwidth (bytes of active weights × generation tok/s) against the
256 GB/s ceiling to see how close generation actually gets — for the MoE models use
*active* parameters, not total.

Deliverable: a tok/s table (prefill and generation × GPU and CPU × model), the two ratio
columns, the bandwidth figures, and a short verdict on when the iGPU is worth it here.

## TASK D — config documentation to update

Edit `machines/homework/configuration.nix`; do **not** deploy (the user always deploys).

1. The long comment on the `wait-for-kfd` ExecStartPre says the workaround is sufficient.
   It isn't. On the last cold boot it logged `KFD node appeared after 2 polls (~1s)` — so
   keep it, the race is live — but ollama's probe *still* found no GPU, and only a manual
   restart got ROCm. The gate tests node *existence*, which the boot proves is too weak.
   Strengthen it: poll until some `/sys/class/kfd/kfd/topology/nodes/*/properties` reports
   a nonzero `gfx_target_version` (it reads `110501` once the driver is genuinely ready).
2. The comment block attributes the post-`offloaded N/N` hang solely to the GTT ceiling.
   Add the SVM/kcompactd deadlock above as a second, distinct cause with the same
   signature, distinguished by GTT usage sitting comfortably *below* the cap and by
   `llama-server` being unkillable in D state.

## Known traps

- `OLLAMA_LOAD_TIMEOUT` is 5m and a cold 61GB load can approach it. `timed out waiting
  for llama-server to start` is the timeout; the deadlock above is the other thing.
- ollama cannot see the GTT cap — it sizes against free system RAM and reports more free
  memory than the cap allows. Unload between models with `"keep_alive": 0`.
- GLM-4.5-Air on CPU (`num_gpu:0`) will be slow. Let it run; that cell is the point of the
  comparison, not a hang.
- Do **not** run `just deploy` — the user always deploys manually.
- Use jj, never git.

---

## Baseline for comparison (pre-reboot, old 62.5 GiB ceiling)

| measurement | value |
|---|---|
| qwen3-coder:30b generation, 100% GPU | 67.5 tok/s |
| qwen3-coder:30b resident @ 32k / 128k / 256k | 21GB / 32GB / 45GB, all 100% GPU |
| gpt-oss:120b KV+compute @ 32k / 128k | 1437 MiB / 5557 MiB |
| gpt-oss:120b weights | 61223 MiB |
| gpt-oss:120b at 28/37 layers (56 GiB GTT) | loaded + generated in 41s |
| gpt-oss:120b at 37/37 layers, old ceiling | hung — **fixed, now 44.7s** |
| NVMe sequential read | 6.0 GB/s (never the bottleneck) |

No prefill baseline worth quoting — the only one taken used a 21-token prompt.
