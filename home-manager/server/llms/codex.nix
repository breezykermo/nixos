{
  inputs,
  llmShared,
  system,
  ...
}: let
  inherit (llmShared) mkSorobanSkillLinks;
in {
  # Codex discovers user Agent Skills under ~/.agents/skills and follows these
  # live out-of-store links. Do not use the obsolete ~/.codex/skills location.
  home.file = mkSorobanSkillLinks ".agents/skills";

  home.packages = [inputs.codex-nix.packages.${system}.codex];
}
