# System-level secrets configuration
#
# Secrets are decrypted at activation time and placed in /run/agenix/
# Home-manager modules can reference them via osConfig.age.secrets.<name>.path
{ userName, ... }:
{
  age.secrets.zuliprc-fcl = {
    file = ./zuliprc-fcl.age;
    owner = userName;
    group = "users";
    mode = "400";
  };
}
