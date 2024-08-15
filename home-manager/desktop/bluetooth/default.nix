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
        # Get this hash via:  nix-prefetch-url --unpack https://github.com/{owner}/{repo}/archive/refs/tags/v{version}.tar.gz
        sha256 = "0czmmv28ys1y8m22y0qzv7cmgdqqkjmv0haw0qbqxf6akhhwzjzn"; 
      };

      cargoHash = lib.fakeHash;

      nativeBuildInputs = [
      ];
    })
  ];
}



