# Feature-flag namespace for per-machine divergence (home-manager side).
#
# Mirrors machines/modules/custom.nix on the system side. Machine-specific home config is
# currently gated by `localProfile == "homework"` comparisons scattered across
# home-manager/ (core.nix, server/llms, desktop, themes). This declares a typed `custom.*`
# namespace those sites can migrate onto so they read `config.custom.homework` instead of
# comparing the profile string.
#
# `custom.homework` is seeded once here from the active machine profile, giving a single
# translation point from machine name to flag. Follow-up issues (nixos-apq, nixos-fma.2)
# move the individual consumer sites over.
#
# Bare `mkEnableOption` here (not nested under `.enable`) since this is a simple on/off
# switch with no sub-config -- see the convention note in machines/modules/custom.nix.
{
  config,
  lib,
  localProfile,
  ...
}: {
  options.custom = {
    homework = lib.mkEnableOption "homework-only home configuration";
  };

  config = {
    custom.homework = lib.mkDefault (localProfile == "homework");
  };
}
