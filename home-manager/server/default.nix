{...}: {
  imports = [
    ./nushell
    ./tmux

    ./bash.nix
    ./core.nix
    ./git.nix
    ./bat.nix
  ];
}
