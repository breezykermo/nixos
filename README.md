# NixOS

## Installing on a new machine
Ensure that the hostname in flake.nix matches the hostname of the new NixOS installation.
Provided that it does, the process should be as simple as running:
```sh
sudo nixos-rebuild switch
```

If this doesn't work, you may also have to ensure that nixos/hardware-configuration.nix is appropriate to the hardware on your machine (i.e. run `sudo nixos-generate-config` and use that file).

Once you have a terminal, run:
```sh
Hyprland
```

## Manual steps
### Secrets

Secrets are managed with [sops-nix](https://github.com/Mic92/sops-nix) and decrypt
automatically at activation — there is no manual unlock step. See [docs/secrets.md](docs/secrets.md).

### Remote SSH access

To reach this machine remotely (e.g. `lox@homework.ohrg.org`) via Tailscale, see
[docs/remote-ssh.md](docs/remote-ssh.md).

