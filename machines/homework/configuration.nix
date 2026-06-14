{ config, lib, pkgs, userName, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

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

  # ── Local LLMs (ollama) — homework only ─────────────────────────────────────
  # ollama itself is enabled for every machine in machines/base.nix; homework is
  # the only box with the RAM (128GB) and the Strix Halo iGPU to run large models,
  # so all the heavy configuration lives here. The models are exposed to Claude
  # Code through claude-code-router (see home-manager/server/llms); switch to one
  # in-session with `/model ollama,<name>`.
  services.ollama = {
    # GPU: the ROCm build runs inference on the Radeon 8060S iGPU (gfx1151) instead
    # of the CPU. The default pkgs.ollama is CPU-only on this box (logs showed
    # `inference compute id=cpu`, `total_vram=0`). gfx1151 is newer than some ROCm
    # builds detect, so force the target with HSA_OVERRIDE_GFX_VERSION. VERIFY AFTER
    # DEPLOY: `journalctl -u ollama | grep -iE 'gpu|rocm|vram'` should show the iGPU
    # and non-zero VRAM. If it still falls back to CPU, try rocmOverrideGfx =
    # "11.0.0" (borrow gfx1100/RDNA3 kernels) or switch package to pkgs.ollama-vulkan
    # (the Vulkan backend is very reliable on Strix Halo).
    package = pkgs.ollama-rocm;
    rocmOverrideGfx = "11.5.1"; # gfx1151 = Radeon 8060S (Strix Halo)

    # Store the models (~170GB for all three) on the 2TB NIXDATA drive mounted at
    # /home/${userName}/data, not the root filesystem.
    models = "/home/${userName}/data/ollama/models";

    # Claude Code sends a large system prompt + tool schema on every turn; ollama's
    # default 4096-token context would silently truncate it and break tool use. Give
    # it real headroom (raise further if you have RAM to spare for the KV cache).
    environmentVariables.OLLAMA_CONTEXT_LENGTH = "32768";

    # Downloaded by ollama-model-loader.service once ollama is up (pull only, runs in
    # the background; ~170GB total on first deploy).
    loadModels = [
      "qwen3-coder:30b"                   # ~19GB · agentic SWE workhorse, native tool calls → CCR default
      "gpt-oss:120b"                      # ~65GB · biggest that fits, native tool calls → CCR think/longContext
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
  systemd.services.ollama.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = lib.mkForce userName;
    Group = lib.mkForce "users";
    ProtectHome = lib.mkForce false;
  };

  # ── Firewall: allow mosh (mobile shell) for resilient remote connections ──
  # mosh uses UDP ports in the range 60000-61000 by default for its connection
  networking.firewall = {
    enable = true;
    allowedUDPPorts = [ 60000 61000 ];
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
    wantedBy = [ "multi-user.target" ];
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
