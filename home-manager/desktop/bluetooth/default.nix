# For reference, see: https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/ba/bat/package.nix
# NOTE: need to develop this on an infinite internet connection...
{ lib, pkgs, ... }: 
{
  home.packages = with pkgs; [
    (rustPlatform.buildRustPackage rec {
      pname = "bluetui";
      version = "0.5.1";

      src = fetchFromGitHub {
        owner = "pythops";
        repo = pname;
        rev = "v${version}"; 
        sha256 = "0czmmv28ys1y8m22y0qzv7cmgdqqkjmv0haw0qbqxf6akhhwzjzn"; 
      };

      cargoHash = "sha256-w6rrZQNu5kLKEWSXFa/vSqwm76zWZug/ZqztMDY7buE=";

      nativeBuildInputs = [ pkg-config ];
    })
  ];
}



