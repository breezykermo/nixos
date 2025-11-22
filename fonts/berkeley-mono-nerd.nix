{
  lib,
  stdenvNoCC,
  nerd-font-patcher,
  python3,
}:

stdenvNoCC.mkDerivation {
  pname = "berkeley-mono-nerd-font";
  version = "1.4.83";

  # Use builtins.path to include directory with filter for TTF files only
  src = builtins.path {
    path = /etc/nixos/fonts/berkeley-mono;
    name = "berkeley-mono-source";
    filter = path: type:
      (type == "directory") ||
      (lib.hasSuffix ".ttf" path);
  };

  nativeBuildInputs = [
    nerd-font-patcher
    python3
  ];

  buildPhase = ''
    runHook preBuild

    mkdir -p $out/share/fonts/truetype

    # Patch each TTF file with Nerd Font glyphs
    for font in $src/*.ttf; do
      nerd-font-patcher "$font" \
        --complete \
        --mono \
        --adjust-line-height \
        --outputdir $out/share/fonts/truetype
    done

    runHook postBuild
  '';

  # Skip install phase since we output directly in buildPhase
  dontInstall = true;

  meta = with lib; {
    description = "Berkeley Mono patched with Nerd Fonts";
    homepage = "https://berkeleygraphics.com/";
    platforms = platforms.all;
  };
}
