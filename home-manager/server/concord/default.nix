{
  inputs,
  pkgs,
  ...
}: let
  # Upstream's flake output fails to build against pipewire >= 1.6; see
  # ./package.nix. The flake input remains the version pin (`just upp
  # i=concord`), we just build its source ourselves.
  concord = pkgs.callPackage ./package.nix {src = inputs.concord;};
in {
  home.packages = [
    # TUI client for Discord
    concord
  ];

  home.shellAliases = {
    ds = "concord";
  };

  xdg.configFile."concord/keymap.toml".text = ''
    [keymap]
    leader = ","
  '';
}
