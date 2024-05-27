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
### Unencrypt secrets

```bash
pbpaste | base64 --decode > ./secret-key
git-crypt unlock ./secret-key
```

See https://lgug2z.com/articles/handling-secrets-in-nixos-an-overview/ for more info.

### Install doom emacs
`git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs`

`~/.config/emacs/bin/doom install`

`~/.config/emacs/bin/doom sync`

(See home-manager/server/emacs/default.nix for more information.)

