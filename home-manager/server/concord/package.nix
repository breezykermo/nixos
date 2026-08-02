{
  lib,
  stdenv,
  rustPlatform,
  pkg-config,
  makeWrapper,
  nasm,
  opus,
  alsa-lib,
  pipewire,
  src,
}:
# Built locally rather than via `inputs.concord.packages.<system>.default` so we
# can patch a vendored crate: libspa-sys 0.10.0 expects bindgen to emit
# `SPA_ID_INVALID`, but pipewire >= 1.6 defines it as `((uint32_t)0xffffffff)`
# and bindgen cannot evaluate cast macros, so the constant is missing from the
# generated bindings and upstream's crane build fails to compile `libspa`.
# Mirrors upstream `nix/package.nix` otherwise.
rustPlatform.buildRustPackage rec {
  pname = "concord";
  version = (lib.importTOML "${src}/Cargo.toml").package.version;

  inherit src;

  cargoLock.lockFile = "${src}/Cargo.lock";

  postPatch = ''
    substituteInPlace "$cargoDepsCopy/libspa-0.10.0/src/constants.rs" \
      --replace-fail "spa_sys::SPA_ID_INVALID" "u32::MAX"
  '';

  # PipeWire generates bindings at build time; bindgenHook supplies libclang.
  # OpenH264 needs NASM on x86_64.
  nativeBuildInputs =
    [
      pkg-config
      rustPlatform.bindgenHook
      makeWrapper
    ]
    ++ lib.optionals stdenv.hostPlatform.isx86_64 [nasm];

  buildInputs = [
    opus
    alsa-lib
    pipewire
  ];

  # Upstream disables tests in the Nix build to keep it fast and reproducible.
  doCheck = false;

  postFixup = ''
    wrapProgram "$out/bin/concord" \
      --set-default PIPEWIRE_CONFIG_DIR "${pipewire}/share/pipewire"
  '';

  meta = {
    description = "Terminal user interface client for Discord";
    homepage = "https://github.com/chojs23/concord";
    license = lib.licenses.gpl3Only;
    mainProgram = "concord";
    platforms = lib.platforms.linux;
  };
}
