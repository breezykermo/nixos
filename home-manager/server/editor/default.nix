{...}: {
  imports = [
    ./neovim
    ./vcs
  ];

  # `e` opens the editor ($EDITOR = nvim via programs.neovim.defaultEditor in ./neovim).
  home.shellAliases.e = "$EDITOR";
}
