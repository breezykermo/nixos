{
  lib,
  pkgs,
  naersk,
  ...
}: let
  mkNaerskGithubPackage = import ../../../pkgs/mkNaerskGithubPackage.nix {inherit pkgs naersk;};
in {
  home.packages = [
    # TUI to easily manage bluetooth
    (mkNaerskGithubPackage {
      name = "bluetui";
      version = "0.6.0";
      owner = "pythops";
      nativeBuildInputs = [pkgs.pkg-config]; # needed at compile time
      buildInputs = [pkgs.dbus pkgs.dbus.dev]; # needed at run time
      sha256 = "0czmmv28ys1y8m22y0qzv7cmgdqqkjmv0haw0qbqxf6akhhwzjzn";
    })
  ];
}
