# Hardware-oriented home configuration for the 128GB Strix Halo machine.
# Coding harness configuration lives under ./llms and gates its own
# homework-only provider settings.
{
  config,
  pkgs,
  lib,
  ...
}: {
  config = lib.mkIf config.custom.homework {
    home.packages = with pkgs; [
      nvtopPackages.amd
      qgis
    ];

    home.sessionVariables.OLLAMA_MODELS =
      "${config.home.homeDirectory}/data/ollama/models";

    # gfx1151 monitoring is not readable through amdsmi/rocm-smi, but keeping
    # ROCm support here retains the existing homework-only btop build.
    programs.btop.package = pkgs.btop.override {rocmSupport = true;};
  };
}
