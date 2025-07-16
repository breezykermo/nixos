############################################################################
#
#  Nix commands related to the local machine
#
############################################################################
#
deploy:
  nixos-rebuild switch --flake . --sudo

debug:
  nixos-rebuild switch --flake . --sudo --show-trace --verbose

up:
  nix flake update

# Update specific input
# usage: make upp i=home-manager
upp:
  nix flake lock --update-input $(i)

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

