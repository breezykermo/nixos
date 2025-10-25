{ config, pkgs, lib, inputs, system, ... }:
{
  #   - Upstream flake.nix has an outdated vendorHash
  #   - Tests require filesystem access not available in Nix sandbox
  home.packages = [
    inputs.beads.packages.${system}.default
    # (inputs.beads.packages.${system}.default.overrideAttrs (oldAttrs: {
    #   vendorHash = "sha256-DJqTiLGLZNGhHXag50gHFXTVXCBdj8ytbYbPL3QAq8M=";
    #   doCheck = false;
    # }))
  ];

  home.sessionVariables = {
    # Claude code
    DISABLE_TELEMETRY = 1;
    DISABLE_ERROR_REPORTING = 1;
    DISABLE_NON_ESSENTIAL_MODEL_CALLS = 1;
  };
}
