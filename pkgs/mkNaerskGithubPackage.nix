# Shared builder for Rust CLI tools fetched from GitHub and built with naersk.
#
# Usage:
#   mkNaerskGithubPackage = import ../../pkgs/mkNaerskGithubPackage.nix { inherit pkgs naersk; };
#   mkNaerskGithubPackage {
#     name = "foo"; version = "1.0.0"; owner = "someuser";
#     sha256 = "...";
#     # optional: repo (defaults to name), rev (defaults to "v${version}"),
#     # nativeBuildInputs, buildInputs
#   }
{
  pkgs,
  naersk,
}: let
  naersk' = pkgs.callPackage naersk {};
in
  {
    name,
    version,
    owner,
    repo ? name,
    rev ? "v${version}",
    sha256,
    nativeBuildInputs ? [],
    buildInputs ? [],
  }:
    naersk'.buildPackage {
      inherit name version nativeBuildInputs buildInputs;
      src = pkgs.fetchFromGitHub {inherit owner repo rev sha256;};
    }
