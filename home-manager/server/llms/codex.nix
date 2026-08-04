{
  inputs,
  system,
  ...
}: {
  home.packages = [inputs.codex-nix.packages.${system}.codex];
}
