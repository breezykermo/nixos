{ config, lib, pkgs, userName, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  # Enable USB automounting
  services.devmon.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # ── Laptop power behaviour ──────────────────────────────────────────────────
  # Opt into the shared laptop policy (machines/modules/laptop.nix): lid-close
  # suspends immediately, then hibernates after the delay defined there.
  custom.laptop = true;

  # Hibernation needs swap >= RAM. This box has 60GiB RAM and NIXROOT is ext4 with
  # plenty free (see hardware-configuration.nix). A swapfile is fine: the initrd's
  # systemd-hibernate-resume-generator auto-detects the resume offset once
  # boot.resumeDevice points at the underlying block device. These live here (not in
  # the shared module) because they hardcode this machine's RAM size and disk label.
  swapDevices = [
    { device = "/var/lib/swapfile"; size = 65536; } # 64GiB: 60GiB RAM + headroom
  ];
  boot.resumeDevice = "/dev/disk/by-label/NIXROOT";

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?
}
