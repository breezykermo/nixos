---
title: Unlock git-crypt secrets
when: You've freshly checked out this repo (or cloned it on a new machine) and the encrypted secrets are still locked
tags: [nix, secrets, git-crypt]
---

```bash
pbpaste | base64 --decode > ./secret-key
git-crypt unlock ./secret-key
```

Notes: the base64-encoded key lives in the password manager; `pbpaste` reads it
from the clipboard. `git-crypt` is a distinct binary from `git`, so it is fine to
run even under the "never git, always jj" rule. Ref:
https://lgug2z.com/articles/handling-secrets-in-nixos-an-overview/
