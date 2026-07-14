{
  # User information
  userName = "lox";
  userFullName = "Lachlan Kermode";
  userEmail = "lachiekermode@gmail.com";
  jjEmail = "lachie@ohrg.org";

  # System settings
  # NOTE: machines/<name>/ dirs are auto-discovered as nixosConfigurations.<name>
  # (see flake.nix); `just deploy` picks which one via machines/local-profile.nix.
  hostname = "loxnix";
  timezone = "Europe/Amsterdam";
  locale = "en_US.UTF-8";

  # Paths
  dropboxPath = "/home/lox/Dropbox/Lachlan Kermode";
  remarkableKey = "remarkable";
  sshKeys = ["id_ed25519" "tangled.org" "remarkable"];
}
