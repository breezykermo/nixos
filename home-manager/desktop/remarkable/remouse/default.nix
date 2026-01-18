{ pkgs, lib, ... }:
let
  remarkable-tablet-driver = pkgs.stdenv.mkDerivation rec {
    pname = "remarkable-tablet-driver";
    version = "unstable-2024-01-01-patched";

    src = pkgs.fetchFromGitHub {
      owner = "FreeCap23";
      repo = "reMarkable-tablet-driver";
      rev = "main";
      sha256 = "sha256-AQhDKzxN+Gkuv0W+P53Xh4pM/iiq8zvKacPXMPYlbW8=";
    };

    # Apply rotation patch by replacing source files
    postPatch = ''
      cp ${./patched/argument_parser.h} src/argument_parser.h
      cp ${./patched/argument_parser.c} src/argument_parser.c
      cp ${./patched/tabletDriver.c} src/tabletDriver.c
    '';

    nativeBuildInputs = [
      pkgs.cmake
      pkgs.pkg-config
    ];

    buildInputs = [
      pkgs.libssh
    ];

    # Upstream has printf(format) which triggers -Werror=format-security
    hardeningDisable = [ "format" ];

    meta = {
      description = "Use reMarkable as a drawing tablet with pressure and tilt on Wayland (with rotation support)";
      homepage = "https://github.com/FreeCap23/reMarkable-tablet-driver";
      license = lib.licenses.gpl3;
      platforms = lib.platforms.linux;
      mainProgram = "rmTabletDriver";
    };
  };
in {
  home.packages = [ remarkable-tablet-driver ];
}
