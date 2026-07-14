############################################################################
#
#  Nix commands related to the local machine
#
############################################################################
#
# Machine is chosen at deploy time from the gitignored per-box marker
# machines/local-profile.nix (e.g. `"framework"`). The Justfile runs at deploy
# time, so unlike flake.nix it CAN read a gitignored file. Each machine is exposed
# as nixosConfigurations.<name>; we pass it as the flake attr.
deploy:
  nixos-rebuild switch --flake .#$(tr -d '"' < machines/local-profile.nix) --sudo --impure

debug:
  nixos-rebuild switch --flake .#$(tr -d '"' < machines/local-profile.nix) --sudo --show-trace --verbose

up:
  nix flake update
  ./scripts/update-pins.sh

# Update specific input
# usage: just upp home-manager
upp input:
  nix flake update {{input}}

# Refresh sha256 hashes in pins.json (skill sources) without touching flake inputs
update-pins:
  ./scripts/update-pins.sh

history:
  nix profile history --profile /nix/var/nix/profiles/system

repl:
  nix repl -f flake:nixpkgs

clean:
  # remove all generations older than 1 days
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 1d

gc:
  # garbage collect all unused nix store entries
  sudo nix-collect-garbage --delete-old

