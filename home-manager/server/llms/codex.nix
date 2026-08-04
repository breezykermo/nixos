{
  inputs,
  llmShared,
  system,
  ...
}: let
  inherit (llmShared) mkFalconrySkillLinks;
in {
  # Codex discovers user Agent Skills under ~/.agents/skills and follows these
  # live out-of-store links. Do not use the obsolete ~/.codex/skills location.
  home.file = mkFalconrySkillLinks ".agents/skills";

  home.packages = [inputs.codex-nix.packages.${system}.codex];
}
