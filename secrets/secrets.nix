# Public keys that can decrypt secrets
#
# To get the machine's age public key from SSH host key:
#   nix-shell -p ssh-to-age --run "ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub"
#
# To create/edit an encrypted secret:
#   nix run github:ryantm/agenix -- -e secrets/zuliprc-fcl.age
let
  # Machine SSH host keys converted to age public keys
  loxnix = "age1REPLACE_WITH_ACTUAL_KEY";
in
{
  "zuliprc-fcl.age".publicKeys = [ loxnix ];
}
