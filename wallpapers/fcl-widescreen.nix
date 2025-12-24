{ pkgs }:

pkgs.stdenv.mkDerivation {
  name = "fcl-widescreen-wallpaper";

  src = ../the-fcl.png;

  buildInputs = [ pkgs.imagemagick ];

  # Don't try to unpack the PNG file
  dontUnpack = true;

  buildPhase = ''
    # Make the logo's background transparent, resize to 384x300
    # Place on off-white 1920x1080 canvas with slight darkening
    magick convert \
      -size 1920x1080 \
      'xc:#FBFAF3' \
      \( $src -fuzz 10% -transparent '#FBFAF3' -resize 384x300! \) \
      -gravity center \
      -composite \
      -brightness-contrast -10x0 \
      -quality 95 \
      wallpaper.png
  '';

  installPhase = ''
    mkdir -p $out
    cp wallpaper.png $out/wallpaper.png
  '';
}
