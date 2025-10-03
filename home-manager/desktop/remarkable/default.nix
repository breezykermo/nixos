# ReMarkable related software 
{ ... }:
{
  imports = [
    # ./remouse
  ];

  home.packages = with pkgs; [
    # NOTE: must purchase the source code, and link to it via:
    #   nix-store --add-fixed sha256 rcu-d2024.001q-source.tar.gz
    rcu
  
    # These are for my fork of remarkable-mouse to work
    (python313.withPackages(ps: with ps; [
      libevdev
      paramiko
      pynput
      screeninfo
      evdev
    ]))
  ];
}
