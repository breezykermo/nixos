{pkgs, osConfig, ...}:
{
  # Zulip terminal client
  #
  # The API key is managed via agenix. To update the secret:
  #   nix run github:ryantm/agenix -- -e secrets/zuliprc-fcl.age
  #
  # Usage: zulip fcl
  #
  home.packages = [
    pkgs.zulip-term
  ];

  # Symlink to the decrypted secret managed by agenix
  home.file.".zuliprc-fcl".source =
    osConfig.age.secrets.zuliprc-fcl.path;

  programs.fish.functions.zulip = ''
    if test (count $argv) -eq 0
      echo "Usage: zulip <profile>"
      echo "Profiles are defined in ~/.zuliprc-<profile>"
      return 1
    end
    zulip-term -c ~/.zuliprc-$argv[1]
  '';
}
