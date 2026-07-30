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

## License

This configuration is released under the [MIT License](LICENSE), with these exceptions that
retain their own terms:

- `fonts/inter/` — Inter, under the SIL Open Font License (see `fonts/inter/LICENSE.txt`).
- `fonts/berkeley-mono/` — proprietary; the `.ttf` files are gitignored and not redistributed.
- `home-manager/desktop/remarkable/remouse/patched/` — patched from
  [FreeCap23/reMarkable-tablet-driver](https://github.com/FreeCap23/reMarkable-tablet-driver),
  which retains its upstream license.

