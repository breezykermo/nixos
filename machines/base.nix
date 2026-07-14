{ config, lib, pkgs, userName, ... }:
{
  imports = [
    ./modules/custom.nix
    ./modules/boot.nix
    ./modules/power-management.nix
    ./modules/laptop.nix
    ./modules/audio.nix
    ./modules/security.nix
    ./modules/keyboard-hardware.nix
    ./modules/usb-automount.nix
  ];

  users.users.${userName} = {
    isNormalUser = true;
    description = "${userName}";
    extraGroups = lib.mkDefault [ "networkmanager" "wheel" "docker" "input" ];
    # Public keys allowed to SSH in as ${userName} (password auth is disabled; see
    # services.openssh in configuration.nix). Public keys are safe to commit. Add the
    # public key of each device you connect FROM.
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCtud4pjc3D6c3JILIrOAAsASUKs4uem7CujVhwE/K6L2+x+AjEMy2Zkw+6onzOao9SKegGyYOrJRLbE8TWtmAyiiUzuTlz4uQSkkmFRm134DR1ItMEEEpRVk+a9tztaJtSdOK5uK934xR0UMn3O+w0J5NgjzlIVYX4GtKQx7kgDm22Asg94jQKRWgtAlA0g7X2kNEMVwACtJSUC9Uq/DdYMhJWsR8u+Wf5PrZ7MjjfmaVTnQrQ3pfblQUx2C8X7w4mUBCKBjx0bbV09q+E5uoyZ6cIzZuOkQcDnrNWQYO60v0AE2BKfDNdGsqWHfDotSVtJaCyx+Gc4jDaZLVtnI2tWY32bEZlTg/fxUwq9HlVj04GDpPpo06Qbx7FZ9/6Sdw2QLVAGh3mr4jGpWvG8wqBB4bEzDxew/Vt+g2q6G7vuLsn4fzLkWApcLixkGw4y96UxxHckccqZ1JBgMM77Gx/Od6FsaQ/B53ZOa2Uzyho8gC9Utrg1FElLVG9fMBq6tM= lox@loxnix"
    ];
  };

  services = {
    # services.printing.enable = true;
    system76-scheduler.settings.cfsProfiles.enable = lib.mkDefault true;
    # ollama is opt-in per machine via `custom.ollama.enable` (see
    # ./modules/custom.nix); only homework turns it on.
  };

  programs.virt-manager.enable = lib.mkDefault false;
}
