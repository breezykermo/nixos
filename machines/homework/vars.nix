{
  # User information
  userName = "lox";
  userFullName = "Lachlan Kermode";
  userEmail = "lachiekermode@gmail.com";
  jjEmail = "lachie@ohrg.org";

  # System settings
  # NOTE: keep hostname "loxnix" -- the flake output is nixosConfigurations.loxnix
  # and `just deploy` (nixos-rebuild --flake .) selects the config by hostname.
  hostname = "loxnix";
  timezone = "Europe/Amsterdam";
  locale = "en_US.UTF-8";

  # Paths
  dropboxPath = "/home/lox/Dropbox/Lachlan Kermode";
  remarkableKey = "remarkable";
  sshKeys = ["id_ed25519" "tangled.org" "remarkable"];
}
