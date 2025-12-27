{ config, pkgs, lib, inputs, system, ... }:
let
  abacus = pkgs.callPackage ./abacus.nix { };
in
{
  #   - Upstream flake.nix has an outdated vendorHash
  #   - Tests require filesystem access not available in Nix sandbox
  home.packages = [
    (inputs.beads.packages.${system}.default.overrideAttrs (oldAttrs: {
      vendorHash = "sha256-l3ctY2hGXskM8U1wLupyvFDWfJu8nCX5tWAH1Macavw=";
      doCheck = false;
    }))
    abacus
  ];

  home.sessionVariables = {
    # Claude code
    DISABLE_TELEMETRY = 1;
    DISABLE_ERROR_REPORTING = 1;
    DISABLE_NON_ESSENTIAL_MODEL_CALLS = 1;
  };
}
