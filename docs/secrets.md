# Secrets management (sops-nix)

`homework` decrypts secrets via [sops-nix](https://github.com/Mic92/sops-nix). There is no
separate age key to generate or back up: `sops.age.sshKeyPaths` in
`machines/homework/configuration.nix` points at the box's existing SSH host key
(`/etc/ssh/ssh_host_ed25519_key`), and sops-nix derives an age identity from it at
activation.

- Age public key (recipient, safe to share): `age1epky306e65eqq42xw2fxqhuhfc2sjp8le4m2wduewl3zaxu774sqnju9jt`
  — derived with `ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub`. Listed in `.sops.yaml` as
  the encryption recipient for everything under `secrets/`.
- If the host key is ever rotated, re-derive the age key with `ssh-to-age` and update
  `.sops.yaml`, then re-encrypt every file under `secrets/` for the new recipient
  (`sops updatekeys secrets/*.yaml`).

## Editing a secrets file

```bash
nix run nixpkgs#sops -- secrets/erwin-linkding.yaml
```

This decrypts to a temp file, opens `$EDITOR`, and re-encrypts on save. Decrypting from the
CLI (rather than editing) requires root, since the private host key is root-only readable:

```bash
sudo env SOPS_AGE_SSH_PRIVATE_KEY_FILE=/etc/ssh/ssh_host_ed25519_key \
  nix run nixpkgs#sops -- --decrypt secrets/erwin-linkding.yaml
```

## secrets/erwin-linkding.yaml

Holds two env-file blobs for the erwin-linkding pattern (see `nixos-wire-7vw` / `nixos-lkd-9t5`):

- `erwin-linkding.drainer-env` — `DRAIN_SECRET` (must match the value set in the Netlify
  dashboard; also kept in `pass`) and `TARGET_TOKEN` (linkding API token, generated after
  first login).
- `erwin-linkding.linkding-env` — `LD_SUPERUSER_NAME` / `LD_SUPERUSER_PASSWORD`, the bootstrap
  admin account.

Both are currently placeholders (`CHANGEME`) — fill in real values with `sops
secrets/erwin-linkding.yaml` before enabling `services.linkding` / `services.erwin-drainer`.
