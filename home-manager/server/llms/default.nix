{ config, pkgs, lib, inputs, system, ... }:
{
  #   - Upstream flake.nix has an outdated vendorHash
  #   - Tests require filesystem access not available in Nix sandbox
  home.packages = [
    (inputs.beads.packages.${system}.default.overrideAttrs (oldAttrs: {
      vendorHash = "sha256-9xtp1ZG7aYXatz02PDTmSRXwBDaW0kM7AMQa1RUau4U=";
      doCheck = false;
    }))
  ];

}
