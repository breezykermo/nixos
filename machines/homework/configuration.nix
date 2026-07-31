{
  config,
  lib,
  pkgs,
  inputs,
  userName,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    inputs.sops-nix.nixosModules.sops
  ];

  # Secrets management (see docs/secrets.md). Reuse the existing SSH host key as the
  # decryption key instead of managing a separate age key: sops-nix derives one from it
  # at activation, so there is nothing extra to generate or back up. Services that need a
  # secret declare their own `sops.secrets.*` (with a `sopsFile` pointing at the relevant
  # file under secrets/) when they're added.
  sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

  # Enable USB automounting
  services.devmon.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # The NIXDATA data drive (see hardware-configuration.nix) mounts at /home/lox/data
  # as a fresh ext4 whose root is owned by root. Make it owned by the primary user so
  # they can actually write to it. tmpfiles runs after local-fs.target, i.e. after the
  # mount, so this chowns the mounted filesystem rather than a hidden underlay.
  #
  # The ollama subdirs (see services.ollama below) live on the same drive but are
  # owned by the ollama service user. ReadWritePaths in the hardened ollama unit
  # requires the models dir to exist at start, so create it here.
  systemd.tmpfiles.rules = [
    "d /home/${userName}/data 0755 ${userName} users - -"
    "d /home/${userName}/data/ollama 0755 ${userName} users - -"
    "d /home/${userName}/data/ollama/models 0755 ${userName} users - -"
  ];

  # ── GPU memory ceiling for the Strix Halo iGPU ──────────────────────────────
  # The 8060S has almost no dedicated VRAM (512 MiB); everything else it uses is
  # system RAM lent to the GPU through GTT. The kernel caps GTT at half of RAM by
  # default — 62.5 GiB here (ttm.pages_limit = 16395667 pages x 4 KiB), which is
  # *below* the largest models we run.
  #
  # That cap is a hard wall, and hitting it does not fail cleanly: ollama sizes its
  # allocation against free *system* RAM (its startup log claims ~117 GiB available,
  # having never heard of the GTT limit), so it happily decides a model fits, then
  # llama-server wedges. Measured with gpt-oss:120b (61223 MiB of weights):
  #   37/37 layers on GPU = 62.6 GiB requested vs 62.5 GiB cap -> hangs forever after
  #     "load_tensors: offloaded 37/37 layers to GPU", one thread spinning at 90% CPU,
  #     GPU 0% busy, zero disk I/O, no progress in 20+ minutes
  #   28/37 layers on GPU = 56 GiB requested -> loads and generates in 41 seconds
  # So this is purely the ceiling, not model size, disk speed or ROCm kernel JIT.
  #
  # Raise the cap to 110 GiB, leaving ~15 GiB for the host. Nothing is preallocated —
  # GTT is a limit, not a reservation, and pages are taken from system RAM on demand
  # — so this costs nothing until a model actually asks for it. gttsize is in MiB;
  # pages_limit is in 4 KiB pages (110 * 262144). Both are needed: ttm.pages_limit is
  # the hard cap, amdgpu.gttsize sizes the GTT domain itself.
  #
  # Caveat: ollama still cannot see this number, so it can still over-commit past it.
  # 110 GiB clears any single model we keep — the two big ones are gpt-oss:120b at
  # ~67 GiB (61 GiB weights + ~5.5 GiB KV at 128k) and GLM-4.5-Air at ~85 GiB.
  #
  # It does NOT clear every *pair* of them. OLLAMA_MAX_LOADED_MODELS is unset, so
  # ollama keeps more than one model warm and decides whether the next one fits using
  # its wrong (system-RAM) view of memory. GLM + gpt-oss is ~152 GiB and GLM +
  # qwen3-coder at 128k is ~115 GiB, both past the cap; gpt-oss + qwen3-coder is
  # ~97 GiB and fits. So the risk is specifically GLM sharing with anything large.
  # If that bites, `environmentVariables.OLLAMA_MAX_LOADED_MODELS = "1"` below forces
  # eviction instead — at the cost of a full reload every time CCR routes between
  # models, which for gpt-oss is not cheap. Left unset for now since CCR's default
  # and think models (qwen3-coder + gpt-oss) are the pair that does fit.
  #
  # If a model ever hangs at "offloaded N/N layers to GPU", compare the projected
  # size in the `common_memory_breakdown_print` log lines against
  # `cat /sys/module/ttm/parameters/pages_limit` (x 4 KiB) before suspecting anything
  # else, and cap the model with `"options": {"num_gpu": <layers>}`.
  #
  # ── SECOND, DISTINCT CAUSE of that same hang: an amdgpu SVM / kcompactd deadlock ──
  #
  # The ceiling above is not the only thing that wedges a load at "offloaded N/N layers
  # to GPU", and the two wear the same disguise. Measured 2026-07-30 with the 110 GiB
  # cap in place: GLM-4.5-Air:Q5_K_M at full offload (48/48 layers) allocates *fine* —
  # `projected to use 78302 MiB`, `ROCm0 model buffer size = 76486.61 MiB`, tensors
  # streamed off NVMe at 1.9 GB/s — and then stops dead immediately after
  # `load_tensors: offloaded 48/48 layers to GPU` with no further log line, ever.
  # Confirmed still wedged at 19 minutes under OLLAMA_LOAD_TIMEOUT=30m, so it is not a
  # timeout. gpt-oss:120b (61 GiB of buffers) is fine; 76 GiB is not — the trigger looks
  # like buffer size, well below the 110 GiB cap.
  #
  # The kernel stacks say it is a lock inversion, not a memory shortage
  # (`journalctl -k -b | grep -A45 'blocked for more than'`; `dmesg` itself is refused
  # because kernel.dmesg_restrict = 1):
  #
  #   llama-server  ioctl(/dev/kfd) -> kfd_ioctl_svm -> svm_range_set_attr -> mutex
  #   kcompactd0    compact_zone -> svm_range_cpu_invalidate_pagetables -> same mutex
  #   both reported "blocked on a mutex likely owned by task kworker/6:0"
  #
  # Memory compaction walks into amdgpu's MMU-notifier invalidate callback, which wants
  # the mutex that the SVM range setup llama-server is waiting on. llama-server then
  # sits in D state and is UNKILLABLE: the ~78 GiB of GTT is never released, kcompactd0
  # stays stuck, and even `ps`/`pgrep`/`pidof` appear to hang because they too enter D
  # state reading the wedged process's /proc entry. Only a reboot recovers.
  #
  # TELLING THE TWO APART: the GTT-ceiling hang has projected size at or above the cap;
  # this one has GTT sitting comfortably *below* it, plus an unkillable D-state
  # llama-server and the stacks above. Ceiling hangs are also killable.
  #
  # MITIGATION, measured 2026-07-30: `vm.compaction_proactiveness=0` (set below) removes
  # the deadlock. kcompactd is literally one of the two participants, so stopping
  # proactive compaction targets the bug directly, and retrying the same GLM-4.5-Air full
  # offload with it set gave a completely different failure: the load still stalled after
  # `offloaded 48/48 layers`, but llama-server stayed in **R** state at 55% CPU, `journalctl
  # -k` logged ZERO `blocked for more than` warnings (hung-task detection fires at 120 s of
  # D state, so nothing was ever wedged), ollama's 5-minute OLLAMA_LOAD_TIMEOUT killed it
  # cleanly, GTT fell from 77 GiB back to 365 MiB and memory returned to 121 GiB available.
  # No reboot needed. An unkillable kernel deadlock became an ordinary failed load.
  #
  # What did NOT get fixed: GLM-4.5-Air still does not finish loading at 48/48 layers. It
  # spends its time in some phase after tensor load that emits no log line and leaves
  # gpu_busy_percent at 0-5%. Whether a longer timeout ever completes it is untested — the
  # cell was abandoned deliberately rather than spend more reboots on it. So treat
  # GLM-4.5-Air as unusable at full offload here: cap it with `"options": {"num_gpu":
  # <layers>}` or run it on CPU (measured 7.1 tok/s generation, 33 tok/s prefill).
  #
  # Benchmark data behind all of the above: ~/ollama-bench/REPORT.md, harness at
  # home-manager/server/llms/examples/ollama-gpu-cpu-bench.py.
  boot.kernelParams = [
    "amdgpu.gttsize=112640"
    "ttm.pages_limit=28835840"
  ];

  # Proactive memory compaction is one half of the amdgpu SVM lock inversion documented
  # above: kcompactd walks into amdgpu's MMU-notifier invalidate callback and deadlocks
  # against a large GPU allocation, leaving llama-server unkillable and the box needing a
  # reboot. 0 disables only the *proactive* background pass; compaction still happens on
  # demand when an allocation needs it, so the cost is at worst some extra latency on huge-
  # page allocations, which this workload does not care about. Verified to convert the
  # unkillable wedge into a clean, recoverable failure. Revert at runtime without a rebuild
  # via `sudo sysctl vm.compaction_proactiveness=20` (20 is the kernel default).
  boot.kernel.sysctl."vm.compaction_proactiveness" = 0;

  # ── Local LLMs (ollama) — homework only ─────────────────────────────────────
  # homework is the only box with the RAM (128GB) and the Strix Halo iGPU to run
  # large models, so it is the only machine that opts into ollama (the flag defaults
  # off in machines/modules/custom.nix). All the heavy configuration lives here. The
  # models are exposed to Claude Code through claude-code-router (see
  # home-manager/server/llms); switch to one in-session with `/model ollama,<name>`.
  custom.ollama.enable = true;
  services.ollama = {
    # GPU: the ROCm build runs inference on the Radeon 8060S iGPU (gfx1151) instead
    # of the CPU. The default pkgs.ollama is CPU-only on this box (logs showed
    # `inference compute id=cpu`, `total_vram=0`). The bundled ROCm 7.2 runtime
    # detects gfx1151 natively, so no rocmOverrideGfx is needed — setting
    # HSA_OVERRIDE_GFX_VERSION only makes discovery log `user overrode visible
    # devices`. VERIFY AFTER DEPLOY: `journalctl -u ollama | grep -iE 'gpu|rocm|vram'`
    # should show `library=ROCm compute=gfx1151` and `total_vram="62.5 GiB"`. If it
    # falls back to CPU, try rocmOverrideGfx = "11.0.0" (borrow gfx1100/RDNA3 kernels)
    # or switch package to pkgs.ollama-vulkan (the Vulkan backend is very reliable on
    # Strix Halo).
    package = pkgs.ollama-rocm;

    # Store the models (~170GB for all three) on the 2TB NIXDATA drive mounted at
    # /home/${userName}/data, not the root filesystem.
    modelsDir = "/home/${userName}/data/ollama/models";

    # Context window. Claude Code sends a large system prompt + tool schema on every
    # turn, so a small window silently truncates it and breaks tool use.
    #
    # This is a DEFAULT, not a cap: /api/generate and /api/chat callers that pass
    # `options.num_ctx` get whatever they ask for regardless of this value (verified —
    # with the env at 32768, a num_ctx=262144 request loaded at 262144). It matters
    # because our actual clients — claude-code-router and qwen-code — talk to the
    # OpenAI-compatible /v1 endpoint, which has no num_ctx field, so they always get
    # this default. For them this number IS the window.
    #
    # 131072 chosen over ollama's own VRAM-derived default (262144 on this box, see
    # `vram-based default context` in the startup log) for two measured reasons.
    #
    # First, 262144 is past what the models were trained for. gpt-oss:120b reports
    # n_ctx_train = 131072, and asking for more only logs `requested context size too
    # large for model num_ctx=262144 n_ctx_train=131072` and gets clamped back down —
    # the bigger number buys nothing there.
    #
    # Second, ollama's default is computed once from total VRAM and applied to every
    # model regardless of weight size, and KV cache is not free. Measured:
    #   qwen3-coder:30b (18GB) resident: 21GB @ 32k, 32GB @ 128k, 45GB @ 256k
    #     — all still "100% GPU" per `ollama ps`
    #   gpt-oss:120b (61223 MiB weights) KV+compute: 1437 MiB @ 32k, 5557 MiB @ 128k
    # gpt-oss at 128k therefore wants ~66.8 GiB total, which only fits because of the
    # raised GTT ceiling above — at the stock 62.5 GiB cap it wedges on load. 128k is
    # the largest window every model here can actually take.
    #
    # If you change this, keep the `contextWindowSize` values in
    # home-manager/server/homework.nix in sync — those are the client-side halves of
    # the same number. Re-measure with:
    #   curl -s http://127.0.0.1:11434/api/generate \
    #     -d '{"model":"qwen3-coder:30b","prompt":"hi","stream":false,
    #          "options":{"num_ctx":131072},"keep_alive":"30s"}' >/dev/null
    #   ollama ps   # PROCESSOR must stay "100% GPU"
    environmentVariables.OLLAMA_CONTEXT_LENGTH = "131072";

    # Downloaded by ollama-model-loader.service once ollama is up (pull only, runs in
    # the background; ~190GB total on first deploy).
    #
    # GLM-4.5-Air only became viable with the raised GTT ceiling above: ~77 GiB of
    # weights plus KV cache is comfortably past the stock 62.5 GiB cap, so before that
    # change it could only ever have loaded partially onto the GPU (or hung). It is
    # the one model here big enough that two of it resident at once cannot fit — see
    # the concurrency note on OLLAMA_MAX_LOADED_MODELS below.
    loadModels = [
      "qwen3.6:35b" # ~24GB · MoE (35B-A3B, Q4_K_M), 256K native ctx → qwen-code default
      "qwen3-coder:30b" # ~19GB · agentic SWE workhorse, native tool calls → CCR default
      "gpt-oss:120b" # ~65GB · native tool calls → CCR think/longContext
      "MichelRosselli/GLM-4.5-Air:Q5_K_M" # ~83GB · strong reasoner (XML tool calls unreliable via ollama)
    ];
  };

  # The hardened ollama unit runs as a throwaway DynamicUser and sets ProtectHome =
  # true. Neither can reach the model store: /home/${userName} is mode 0700, so only
  # ${userName} can traverse into its data dir, and ProtectHome hides /home entirely.
  # Since the models live in the user's own data dir, run the daemon as ${userName}
  # and expose /home. ProtectSystem = "strict" still keeps the whole filesystem
  # read-only apart from the models dir (which the module adds to ReadWritePaths) and
  # the StateDirectory. We override serviceConfig directly rather than via
  # services.ollama.user so the module doesn't try to redeclare the existing
  # ${userName} account as a system user.
  #
  # ── WORKAROUND: cold-boot GPU discovery race (ollama 0.32.1, 2026-07) ────────
  #
  # Symptom: after a cold boot the daemon logs `inference compute id=cpu` and
  # `vram-based default context total_vram="0 B"`, then serves every request on the
  # CPU for the rest of the uptime. `systemctl restart ollama` by hand immediately
  # fixes it — same binary, same environment, GPU found.
  #
  # Cause: ollama probes for GPUs exactly once, at startup, and caches the result.
  # The upstream unit is ordered only `After = network.target`, which says nothing
  # about hardware, so on a cold boot it can win the race against udev creating the
  # amdgpu compute node (/dev/kfd). Discovery finds nothing and never retries.
  #
  # Ruled out while diagnosing, so don't re-chase these: the ROCm build is correct
  # (lib/ollama/rocm_v7_2/libggml-hip.so is present), the device nodes are readable
  # by the service user, and none of the sandboxing above blocks ROCm —
  # MemoryDenyWriteExecute, PrivateUsers, ProtectSystem=strict, ProtectProc,
  # PrivateTmp and DevicePolicy=closed were each tested individually and discovery
  # succeeded under all of them.
  #
  # Fix: block startup until the GPU node is genuinely ready. There is no
  # `dev-kfd.device` unit to order against — udev doesn't tag the node — so poll.
  # Timing out starts the daemon anyway rather than failing the unit: degraded CPU
  # inference beats no ollama.
  #
  # The gate deliberately tests more than the device nodes' existence. On the cold boot
  # of 2026-07-30 the earlier version of this script logged `KFD node appeared after 2
  # polls (~1s)` — so it did wait, and the race is real — and yet ollama's probe *still*
  # came back `library=cpu` / `total_vram="0 B"`, and only a manual `systemctl restart
  # ollama` produced ROCm. `/dev/kfd` and `/dev/dri/renderD128` therefore appear before
  # amdgpu has finished bringing the compute node up, which makes existence too weak a
  # signal. The stronger one is the topology: each node under
  # /sys/class/kfd/kfd/topology/nodes/*/properties carries a `gfx_target_version`, which
  # reads 0 until the driver has really populated it and 110501 (gfx1151) once it has.
  # Note node 0 is the CPU node and reports 0 permanently, hence the match on *any* node
  # with a nonzero version rather than on a particular one.
  #
  # IS THIS STILL NEEDED? The script says so itself on every start, so just read the
  # log after a reboot:
  #
  #   journalctl -u ollama -b | grep wait-for-kfd
  #
  # "node already present at unit start" on several consecutive COLD boots (a warm
  # `systemctl restart` always shows this and proves nothing — the node is long since
  # up) means whatever fixed it upstream is in place and this block can go. "waited
  # N polls" means the race is still live. Re-check after any ollama, mesa/ROCm,
  # kernel or systemd bump: the upstream fix would be ollama retrying discovery
  # instead of caching one failed probe, or its unit gaining a real hardware
  # ordering dependency. To confirm removal, delete the ExecStartPre, deploy, cold
  # boot, and check `journalctl -u ollama -b | grep 'inference compute'` shows
  # `library=ROCm compute=gfx1151` rather than `id=cpu`.
  systemd.services.ollama.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = lib.mkForce userName;
    Group = lib.mkForce "users";
    ProtectHome = lib.mkForce false;
    ExecStartPre = [
      "${pkgs.writeShellScript "ollama-wait-for-kfd" ''
        polls=0
        while [ "$polls" -lt 60 ]; do
          # Nodes exist AND amdgpu has populated a real gfx_target_version (110501 for
          # gfx1151). Node 0 is the CPU node and stays 0, so match any nonzero one.
          if [ -e /dev/kfd ] && [ -e /dev/dri/renderD128 ] \
             && ${pkgs.gnugrep}/bin/grep -qsE '^gfx_target_version[[:space:]]+[1-9]' \
                  /sys/class/kfd/kfd/topology/nodes/*/properties; then
            if [ "$polls" -eq 0 ]; then
              echo "ollama-wait-for-kfd: KFD GPU node ready at unit start (gfx_target_version populated)" >&2
            else
              echo "ollama-wait-for-kfd: KFD GPU node became ready after $polls polls (~$((polls / 2))s) - boot race still live, keep this ExecStartPre" >&2
            fi
            exit 0
          fi
          polls=$((polls + 1))
          sleep 0.5
        done
        echo "ollama-wait-for-kfd: no KFD node with a populated gfx_target_version after 30s, starting anyway (expect CPU inference; 'systemctl restart ollama' recovers ROCm)" >&2
      ''}"
    ];
  };

  # ── SECOND HALF OF THE SAME WORKAROUND: verify the probe, don't just gate it ──
  #
  # The ExecStartPre above is a *proxy* for readiness, and measurement says the proxy
  # is not tight enough. Cold boot of 2026-07-31 10:18: the gate logged "KFD GPU node
  # became ready after 2 polls (~1s)" — so gfx_target_version was populated — and
  # ollama's probe still came back `id=cpu library=cpu` / `total_vram="0 B"`. Every
  # model then ran at `100% CPU` per `ollama ps` for the whole 12-hour uptime. The
  # cold boot of 2026-07-30 14:11 waited the same 2 polls and *did* get ROCm, so the
  # signal is genuinely racy rather than simply wrong, and no stronger sysfs proxy has
  # been found. Across the two days, 3 of 4 cold boots lost the race while 4 of 4
  # manual `systemctl restart ollama` won it.
  #
  # So stop guessing at a proxy and check the ground truth instead: ollama logs the
  # result of its one-shot probe as `msg="inference compute"`, naming either
  # `library=ROCm compute=gfx1151` or `library=cpu`. This unit reads that line for the
  # current boot and, if it says cpu, restarts ollama exactly once — which is the same
  # remedy that has always worked by hand, just applied automatically and ~2s after
  # boot instead of whenever the CPU-speed inference is noticed.
  #
  # Ordered Before ollama-model-loader.service (the `loadModels` puller) so the restart
  # can't interrupt a `/api/pull` mid-download; the loader waits for this oneshot.
  # Exits 0 on every path, including "still CPU-only after the restart" — degraded
  # inference beats a failed boot, matching the ExecStartPre's timeout behaviour.
  #
  # THIS BLOCK GOES AWAY WITH THE ONE ABOVE. Both exist only because ollama probes
  # once and caches; the upstream fix is retrying discovery or a real hardware
  # ordering dependency on its unit. `journalctl -u ollama-gpu-recheck -b` tells you
  # which case each boot hit — "probe already found ROCm" on several consecutive cold
  # boots means the race is gone and this can be deleted along with the ExecStartPre.
  systemd.services.ollama-gpu-recheck = {
    description = "Restart ollama once if its startup GPU probe came back CPU-only";
    after = [ "ollama.service" ];
    wants = [ "ollama.service" ];
    before = [ "ollama-model-loader.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      journalctl=${config.systemd.package}/bin/journalctl
      systemctl=${config.systemd.package}/bin/systemctl
      grep=${pkgs.gnugrep}/bin/grep

      probes() {
        $journalctl -u ollama.service -b --no-pager -o cat \
          | $grep -F 'msg="inference compute"' || true
      }
      probe_count() { probes | ${pkgs.coreutils}/bin/wc -l; }
      latest_probe() { probes | ${pkgs.coreutils}/bin/tail -1; }

      # Wait for at least $1 probe lines to exist, up to 30s.
      wait_for_probes() {
        polls=0
        while [ "$polls" -lt 60 ]; do
          if [ "$(probe_count)" -ge "$1" ]; then
            return 0
          fi
          polls=$((polls + 1))
          sleep 0.5
        done
        return 1
      }

      if ! wait_for_probes 1; then
        echo "ollama-gpu-recheck: no 'inference compute' line within 30s of ollama start; leaving the daemon alone" >&2
        exit 0
      fi

      case "$(latest_probe)" in
        *library=ROCm*)
          echo "ollama-gpu-recheck: probe already found ROCm, nothing to do (cold-boot race may be fixed upstream - see the comment in machines/homework/configuration.nix)" >&2
          exit 0
          ;;
      esac

      echo "ollama-gpu-recheck: startup probe came back CPU-only, restarting ollama once to re-probe" >&2
      $systemctl restart --no-block ollama.service

      if ! wait_for_probes 2; then
        echo "ollama-gpu-recheck: restart produced no new 'inference compute' line within 30s; giving up (expect CPU inference)" >&2
        exit 0
      fi

      case "$(latest_probe)" in
        *library=ROCm*)
          echo "ollama-gpu-recheck: ROCm recovered after one restart" >&2
          ;;
        *)
          echo "ollama-gpu-recheck: still CPU-only after one restart - this is no longer just the boot race, investigate the ROCm runtime (expect CPU inference)" >&2
          ;;
      esac
    '';
  };

  # ── Containers (docker + compose) — homework only ───────────────────────────
  # This is the always-on box that services and dev containers actually run on, so it is
  # the only machine that opts into the docker daemon (the flag defaults off in
  # machines/modules/custom.nix). Enabling it also adds ${userName} to the `docker` group
  # (machines/base.nix) — that is root-equivalent via the socket, which is why the
  # laptops stay off. Both `docker compose` and `docker-compose` are available.
  custom.docker.enable = true;

  # ── Firewall: allow mosh (mobile shell) for resilient remote connections ──
  # mosh picks the first free UDP port from the bottom of its range (default 60000-61000).
  # allowedUDPPorts takes INDIVIDUAL ports, so [60000 61000] opened only those two and blocked
  # every port mosh actually lands on. Use a contiguous range instead; a handful is plenty for
  # one user (connect with `mosh -p 60000:60010 …` if mosh ever needs pinning to this window).
  networking.firewall = {
    enable = true;
    allowedUDPPortRanges = [
      {
        from = 60000;
        to = 60010;
      }
    ];
  };

  # ── homework: Framework DESKTOP (Ryzen AI MAX+ 395 / Strix Halo) as an always-on server ──
  # This machine has no battery and no lid, and is SSH'd into for long-running tasks
  # (see docs/remote-ssh.md). The shared laptop power module
  # (machines/modules/power-management.nix) is wrong here: TLP was pinning the powersave
  # governor AND disabling turbo boost (CPU_BOOST_ON_AC = 0), capping this
  # 16-core/32-thread chip to base clock. thermald is Intel-only and does nothing on AMD.
  # Disable the laptop tooling and tune for desktop throughput.
  services.tlp.enable = lib.mkForce false;
  services.thermald.enable = lib.mkForce false;

  # amd-pstate is already in active (EPP) mode. The "powersave" governor in this
  # mode still ramps to full boost clocks under load, so keep it for efficiency,
  # but re-enable turbo boost and lean the energy/performance preference toward
  # performance so long-running compute is not throttled while still clocking down
  # when idle (quiet/cool at home, full ~5GHz boost under load).
  powerManagement.cpuFreqGovernor = "powersave";

  systemd.services.amd-server-cpu-tuning = {
    description = "Enable CPU turbo boost and set EPP for desktop server use";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      echo 1 > /sys/devices/system/cpu/cpufreq/boost
      for epp in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
        echo balance_performance > "$epp"
      done
    '';
  };

  # Stay available when the screens turn off: that is only DPMS and never suspends
  # the system. There is no lid, idle-suspend is already disabled (hypridle skips
  # suspend on the "homework" profile), and sleep targets are inactive. As belt-and
  # -braces for a headless server, stop an accidental power-button tap from taking
  # the box down (a long press still powers off intentionally).
  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandlePowerKeyLongPress = "poweroff";
    IdleAction = "ignore";
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?
}
