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
  systemd.tmpfiles.rules = [
    "d /home/${userName}/data 0755 ${userName} users - -"
  ];

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
