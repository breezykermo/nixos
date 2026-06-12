{ inputs, system, ... }:
{
  home.packages = [
    # TUI client for Discord
    inputs.concord.packages.${system}.default
  ];

  home.shellAliases = {
    ds = "concord";
  };
}
