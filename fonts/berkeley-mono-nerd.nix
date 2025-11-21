{
  lib,
  stdenvNoCC,
  nerd-font-patcher,
  python3,
}:

stdenvNoCC.mkDerivation {
  pname = "berkeley-mono-nerd-font";
  version = "1.4.83";

  # Use absolute path to access fonts outside flake source
  src = /etc/nixos/fonts/berkeley-mono;

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
