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

## Adding a secret for a new service

1. Create `secrets/<service>.yaml` with the plaintext keys you need, e.g.:
   ```yaml
   my-service:
     env: |
       SOME_TOKEN=...
   ```
2. Encrypt it in place: `nix run nixpkgs#sops -- --encrypt --in-place secrets/<service>.yaml`
   (matches automatically via the `secrets/*.yaml` rule in `.sops.yaml`).
3. In the machine config, declare:
   ```nix
   sops.secrets."my-service/env" = {
     sopsFile = ../../secrets/<service>.yaml;
   };
   ```
   then reference `config.sops.secrets."my-service/env".path` (e.g. as a systemd
   `EnvironmentFile`).

## Editing an existing secrets file

```bash
nix run nixpkgs#sops -- secrets/<service>.yaml
```

This decrypts to a temp file, opens `$EDITOR`, and re-encrypts on save. Decrypting from the
CLI (rather than editing) requires root, since the private host key is root-only readable:

```bash
sudo env SOPS_AGE_SSH_PRIVATE_KEY_FILE=/etc/ssh/ssh_host_ed25519_key \
  nix run nixpkgs#sops -- --decrypt secrets/<service>.yaml
```
