{
  imports = [
    ./tui
    ./gui
  ];

  xdg = {
    userDirs = {
      enable = true;
      desktop = "$HOME/.desktop";
      documents = "$HOME/documents";
      download = "$HOME/downloads";
      music = "$HOME/music";
      pictures = "$HOME/pictures";
    };
  };
}
