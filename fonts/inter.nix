{
  stdenvNoCC,
  lib,
}:
stdenvNoCC.mkDerivation {
  pname = "Inter";
  version = "4.0";
  src = ./inter;
 
  installPhase = ''
    mkdir -p $out/share/fonts/TTF/
    cp -r $src/*.ttf $out/share/fonts/TTF/
  '';
 
  meta = with lib; {
    description = "Inter fonts";
    homepage = "https://rsms.me/inter";
    platforms = platforms.all;
  };
}
