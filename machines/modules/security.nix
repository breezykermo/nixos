{ lib, ... }:
{
  # Screen locking on suspend/hibernate
  services.physlock = {
    enable = lib.mkDefault true;
    lockMessage = lib.mkDefault "<lox>";
    allowAnyUser = lib.mkDefault true;
    lockOn = {
      suspend = lib.mkDefault true;
      hibernate = lib.mkDefault true;
    };
  };

  # SSH agent for git access to private repos
  programs.ssh.startAgent = lib.mkDefault true;
}
