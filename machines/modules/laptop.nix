# Laptop power/input behaviour, gated on the `custom.laptop` flag (declared in
# ./custom.nix). This holds only the hardware-INDEPENDENT policy; machine-specific
# capability that references a particular disk/RAM (e.g. the hibernation swapfile and
# resume device) lives in that machine's own configuration.nix.
#
# Opt a machine in with `custom.laptop = true;` in its configuration.nix.
{
  config,
  lib,
  ...
}: let
  cfg = config.custom;
in {
  config = lib.mkIf cfg.laptop {
    # Suspend immediately on lid-close (instant, low-latency resume for short
    # closures), then transition to a full hibernate-to-disk after HibernateDelaySec
    # so the battery barely moves over many hours. mkDefault so a laptop that wants
    # different lid behaviour (e.g. dellxps, always on AC, sets HandleLidSwitch =
    # "ignore" with a plain assignment) still wins.
    services.logind.settings.Login = {
      HandleLidSwitch = lib.mkDefault "suspend-then-hibernate";
      HandleLidSwitchDocked = lib.mkDefault "suspend-then-hibernate";
      HandleLidSwitchExternalPower = lib.mkDefault "suspend-then-hibernate";
    };
    systemd.sleep.settings.Sleep.HibernateDelaySec = lib.mkDefault "45min";
  };
}
