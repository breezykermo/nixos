{
  inputs,
  system,
  ...
}: {
  home.packages = [
    # TUI client for Discord
    inputs.concord.packages.${system}.default
  ];

  home.shellAliases = {
    ds = "concord";
  };

  xdg.configFile."concord/keymap.toml".text = ''
    [keymap]
    leader = ","
  '';
}
