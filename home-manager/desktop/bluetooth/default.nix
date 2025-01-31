{ lib, pkgs, naersk, ... }: 
let
  naersk' = pkgs.callPackage naersk {};
in
{
  home.packages = with pkgs; [
    # Bluetooth protocol stack for Linux
    # bluez
    
    # TUI to easily manage bluetooth
    (naersk'.buildPackage rec {
      name = "bluetui";
      version = "0.6.0";

      # Needed at compile time
      nativeBuildInputs = [
        pkg-config
      ];

      # Needed at run time 
      buildInputs = [
        dbus
        dbus.dev 
      ];

      src = fetchFromGitHub {
        owner = "pythops";
        repo = name;
        rev = "v${version}"; 
        sha256 = "0czmmv28ys1y8m22y0qzv7cmgdqqkjmv0haw0qbqxf6akhhwzjzn"; 
      };
    })
  ];
}



