{ config, pkgs, lib, inputs, system, ... }:
let
  abacus = pkgs.callPackage ./abacus.nix { };
  beads = pkgs.callPackage ./beads.nix { };
in
{
  home.packages = [
    beads
    abacus
    inputs.llm-agents.packages.${system}.claude-code
    inputs.llm-agents.packages.${system}.claude-code-router
  ];

  home.sessionVariables = {
    # Claude code
    DISABLE_TELEMETRY = 1;
    DISABLE_ERROR_REPORTING = 1;
    DISABLE_NON_ESSENTIAL_MODEL_CALLS = 1;
  };
}
