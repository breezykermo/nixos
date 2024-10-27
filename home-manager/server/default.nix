{ ... }:
{
  imports = [
    ./core.nix
    ./fish
    ./tmux
    ./neovim
    ./node
    ./llms
    ./mail
    ./irc
    ./_inprogress
  ];
}
