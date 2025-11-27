############################################################################
#
#  Nix commands related to the local machine
#
############################################################################
#
deploy:
  nixos-rebuild switch --flake . --sudo --impure

debug:
  nixos-rebuild switch --flake . --sudo --show-trace --verbose

up:
  nix flake update

# Update specific input
# usage: just upp home-manager
upp input:
  nix flake update {{input}}

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

