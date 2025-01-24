{
  stdenvNoCC,
  lib,
}:
stdenvNoCC.mkDerivation {
  pname = "Berkeley Mono";
  version = "1.4.83";
  src = ./berkeley-mono;
 
  installPhase = ''
    mkdir -p $out/share/fonts/TTF/
    cp -r $src/*.ttf $out/share/fonts/TTF/
  '';
 
  meta = with lib; {
    description = "Berkeley Mono";
    homepage = "https://berkeleygraphics.com/";
    platforms = platforms.all;
  };
}
