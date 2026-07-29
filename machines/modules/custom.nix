# Feature-flag namespace for per-machine divergence (system side).
#
# Instead of gating machine-specific behaviour with `localProfile == "homework"` string
# comparisons and ad-hoc `lib.mkForce`/`lib.mkDefault` juggling, each machine declares
# its intent as typed flags under `custom.*`, and features gate their config on those
# flags via `lib.mkIf`. Ported from RyanGibb/nixos (see its modules/default.nix +
# modules/laptop.nix).
#
# Set the flags in each machine's own configuration.nix (e.g.
# machines/homework/configuration.nix sets `custom.ollama.enable = true`). Add new flags
# here as more features migrate off `localProfile`.
#
# Convention for new flags:
# - Simple on/off switch with no sub-config: bare `lib.mkEnableOption` (laptop-style).
# - Whole feature with its own sub-config living elsewhere: nest under `.enable`
#   (ollama-style), so later options can hang off the same attrset.
# - A tunable value on an already-enabled feature, not a feature gate itself: a plain
#   `lib.mkOption` (bluetooth.powerOnBoot-style).
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom;
in {
  options.custom = {
    # Laptop power/input tweaks. Placeholder for a later migration of the shared
    # power-management module (machines/modules/power-management.nix); declared now so
    # machines can begin expressing this as a flag.
    laptop = lib.mkEnableOption "laptop power and input tweaks";

    # Local ollama LLM server. Only a machine with the RAM/GPU to actually serve models
    # (currently just homework) should turn this on; the heavy per-machine config
    # (package, models, GPU overrides) lives in that machine's configuration.nix.
    ollama.enable = lib.mkEnableOption "local ollama server";

    # Docker daemon + compose. Opt-in per machine (currently only homework, which is the
    # always-on box that actually runs containers): the daemon is a persistent root
    # service and a `docker` group member is effectively root, so the laptops leave it
    # off. Enabling this also puts the primary user in the `docker` group (see
    # machines/base.nix) so `docker` works without sudo.
    docker.enable = lib.mkEnableOption "docker daemon and compose";

    # Power the Bluetooth radio on at boot. Defaults on; a machine that doesn't rely on
    # Bluetooth peripherals (e.g. framework) can set this false to save idle power while
    # keeping the stack available (turn it on on demand with the `bt-on` alias).
    bluetooth.powerOnBoot = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Power the Bluetooth radio on at boot.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.ollama.enable {
      services.ollama.enable = true;
    })
    (lib.mkIf cfg.docker.enable {
      virtualisation.docker = {
        enable = true;
        # Socket-activate the daemon instead of starting it at boot: it spins up on the
        # first `docker` call and costs nothing until then.
        enableOnBoot = false;
        # Reclaim dangling images/containers/networks weekly so the store of built
        # layers doesn't grow without bound.
        autoPrune = {
          enable = true;
          dates = "weekly";
        };
      };

      # `docker compose` (the v2 subcommand) already works: pkgs.docker bundles the
      # compose CLI plugin by default. This adds the standalone `docker-compose`
      # executable as well, since plenty of projects' scripts still call it by that name.
      environment.systemPackages = [pkgs.docker-compose];
    })
    {
      hardware.bluetooth.powerOnBoot = cfg.bluetooth.powerOnBoot;
    }
  ];
}
