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
  boot.kernelParams = [
    "amdgpu.gttsize=112640"
    "ttm.pages_limit=28835840"
  ];

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
  # Fix: block startup until the node exists. There is no `dev-kfd.device` unit to
  # order against — udev doesn't tag the node — so poll. Timing out starts the daemon
  # anyway rather than failing the unit: degraded CPU inference beats no ollama.
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
          if [ -e /dev/kfd ] && [ -e /dev/dri/renderD128 ]; then
            if [ "$polls" -eq 0 ]; then
              echo "ollama-wait-for-kfd: KFD node already present at unit start" >&2
            else
              echo "ollama-wait-for-kfd: KFD node appeared after $polls polls (~$((polls / 2))s) - boot race still live, keep this ExecStartPre" >&2
            fi
            exit 0
          fi
          polls=$((polls + 1))
          sleep 0.5
        done
        echo "ollama-wait-for-kfd: no /dev/kfd after 30s, starting anyway (expect CPU inference)" >&2
      ''}"
    ];
  };

  # ── Containers (docker + compose) — homework only ───────────────────────────
  # This is the always-on box that services and dev containers actually run on, so it is
  # the only machine that opts into the docker daemon (the flag defaults off in
  # machines/modules/custom.nix). Enabling it also adds ${userName} to the `docker` group
  # (machines/base.nix) — that is root-equivalent via the socket, which is why the
  # laptops stay off. Both `docker compose` and `docker-compose` are available.
  custom.docker.enable = true;

  # ── Firewall: allow mosh (mobile shell) for resilient remote connections ──
  # mosh uses UDP ports in the range 60000-61000 by default for its connection
  networking.firewall = {
    enable = true;
    allowedUDPPorts = [60000 61000];
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
