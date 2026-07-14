{
  lib,
  stdenv,
  fetchurl,
}:
stdenv.mkDerivation rec {
  pname = "beads_rust";
  version = "0.2.15";

  src = fetchurl {
    url = "https://github.com/Dicklesworthstone/beads_rust/releases/download/v${version}/br-${version}-linux_musl_amd64.tar.gz";
    hash = "sha256-c/fxDvhyKYAE9+bXH4KiF9tDUv3OCiL0vENYaPpwDTY=";
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 br $out/bin/br
    runHook postInstall
  '';

  meta = with lib; {
    description = "Fast Rust port of beads: local-first issue tracker (SQLite + JSONL)";
    homepage = "https://github.com/Dicklesworthstone/beads_rust";
    license = licenses.mit;
    mainProgram = "br";
    platforms = ["x86_64-linux"];
  };
}
