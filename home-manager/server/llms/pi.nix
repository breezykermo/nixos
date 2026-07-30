{
  lib,
  buildNpmPackage,
  fetchzip,
  nodejs_24,
  makeWrapper,
}:
# pi coding agent (https://pi.dev), built from the release source tarball.
#
# Bumping the version needs both hashes refreshed:
#   V=0.84.0
#   nix-prefetch-url --unpack https://github.com/earendil-works/pi/releases/download/v$V/pi-$V-source.tar.gz \
#     | tail -1 | xargs nix hash convert --hash-algo sha256 --to sri   # -> src.hash
#   tar -xzf <that tarball> && nix run nixpkgs#prefetch-npm-deps -- pi-$V/package-lock.json  # -> npmDepsHash
buildNpmPackage (finalAttrs: {
  pname = "pi-coding-agent";
  version = "0.83.0";

  src = fetchzip {
    url = "https://github.com/earendil-works/pi/releases/download/v${finalAttrs.version}/pi-${finalAttrs.version}-source.tar.gz";
    hash = "sha256-6gN1KVzpEGI8wx5oYmoNwtU4sfw4ZCAWanXmmnlLQ2E=";
  };

  npmDepsHash = "sha256-AbSfP1Ion8bN309NUBQb1QSn2cIIUjNONmZgls9vnYE=";

  nodejs = nodejs_24;

  nativeBuildInputs = [makeWrapper];

  # Matches upstream's documented `npm install --ignore-scripts`. Without it npm
  # tries to node-gyp-build `canvas` (an eval-harness dep the CLI never loads).
  npmFlags = ["--ignore-scripts"];

  # Upstream `npm run build` calls generate-models, which hits live provider
  # catalogs over the network. build:offline uses the model-data snapshot that
  # ships in the release source tarball instead.
  npmBuildScript = "build:offline";

  # The build-only toolchain (biome, rolldown, typescript/tsgo, esbuild,
  # lightningcss) is ~200MB of the installed closure and is dead weight at
  # runtime.
  postBuild = ''
    npm prune --omit=dev --ignore-scripts
  '';

  # Monorepo: the default npm install hook expects a single publishable
  # package. Keep the workspace tree (relative node_modules symlinks into
  # packages/* must stay intact) and wrap the coding-agent CLI entrypoint.
  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/pi
    cp -R package.json package-lock.json packages node_modules $out/lib/pi/

    makeWrapper ${finalAttrs.nodejs}/bin/node $out/bin/pi \
      --add-flags $out/lib/pi/packages/coding-agent/dist/cli.js

    runHook postInstall
  '';

  meta = {
    description = "Minimal, hackable coding agent CLI (pi.dev)";
    homepage = "https://pi.dev";
    license = lib.licenses.mit;
    maintainers = [];
    mainProgram = "pi";
    platforms = lib.platforms.unix;
  };
})
