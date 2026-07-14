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
{ config, lib, ... }:
let
  cfg = config.custom;
in
{
  options.custom = {
    # Laptop power/input tweaks. Placeholder for a later migration of the shared
    # power-management module (machines/modules/power-management.nix); declared now so
    # machines can begin expressing this as a flag.
    laptop = lib.mkEnableOption "laptop power and input tweaks";

    # Local ollama LLM server. Only a machine with the RAM/GPU to actually serve models
    # (currently just homework) should turn this on; the heavy per-machine config
    # (package, models, GPU overrides) lives in that machine's configuration.nix.
    ollama.enable = lib.mkEnableOption "local ollama server";
  };

  config = lib.mkIf cfg.ollama.enable {
    services.ollama.enable = true;
  };
}
