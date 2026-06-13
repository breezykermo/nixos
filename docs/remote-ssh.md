# Remote SSH access to `homework` (`lox@homework.ohrg.org`)

This document explains how the `homework` machine is made reachable for SSH from outside
the home network, why Tailscale was chosen over directly exposing SSH to the internet, and
the one-time manual steps required to bring it online.

> `homework` is the `localProfile` name for this Framework machine. Its NixOS hostname is
> `loxnix` (see `machines/framework/vars.nix`).

## Table of Contents
1. [Goal](#goal)
2. [Approach: Tailscale overlay](#approach-tailscale-overlay)
3. [Why not expose SSH directly?](#why-not-expose-ssh-directly)
4. [What's configured in this repo](#whats-configured-in-this-repo)
5. [One-time setup steps](#one-time-setup-steps)
6. [Connecting](#connecting)
7. [Verification](#verification)
8. [Caveats and alternatives](#caveats-and-alternatives)

---

## Goal

SSH into this machine as `lox@homework.ohrg.org` from anywhere (e.g. while travelling),
using a real hostname under the `ohrg.org` domain (DNS hosted on Netlify).

## Approach: Tailscale overlay

We use [Tailscale](https://tailscale.com), a WireGuard-based mesh VPN. When enabled, this
machine joins a private "tailnet" and receives a **stable** address in the `100.x.y.z` range.
We then publish a single static DNS record pointing the desired hostname at that address:

```
A  homework.ohrg.org  ->  100.x.y.z
```

Any device that is also logged into the same tailnet can then run `ssh lox@homework.ohrg.org`
and reach the machine — from any network, without router configuration.

Key properties:
- **No router/port-forwarding** and works behind NAT or carrier-grade NAT.
- **Survives dynamic IP changes** — the home connection's public IPv4 and IPv6 prefix are
  ISP-assigned and change over time, but the Tailscale `100.x` address is stable, so no
  dynamic-DNS updater is needed. A one-time manual Netlify record is sufficient.
- **SSH is never exposed to the public internet** — only tailnet members can reach port 22.

## Why not expose SSH directly?

Direct exposure (a router port-forward for IPv4 and/or an IPv6 firewall pinhole, plus a
dynamic-DNS updater to track the changing address) is technically viable here — the home
connection has a real, non-CGNAT public IPv4 and working public IPv6. It was rejected because
it requires router admin access, puts SSH in front of internet scanners (relying on key-only
auth and `fail2ban` to stay safe), and needs dynamic-DNS plumbing because both the IPv4 and
the IPv6 prefix are dynamic. Tailscale avoids all of that for the personal-machine use case.

The trade-off: the device you connect **from** must also run Tailscale and be logged into the
same tailnet. (See [Caveats and alternatives](#caveats-and-alternatives) for the direct route
if you ever need to connect from a machine that can't run Tailscale.)

## What's configured in this repo

The SSH server was already enabled before this change (`services.openssh.enable = true` with
`PasswordAuthentication = false` in `configuration.nix`), and the host firewall already permits
port 22 (`openFirewall` defaults to true). Two changes complete the remote-access setup:

| File | Change |
| --- | --- |
| `configuration.nix` | `services.tailscale.enable = true;` — installs the daemon and opens its UDP port. |
| `machines/base.nix` | `users.users.${userName}.openssh.authorizedKeys.keys` — public key(s) allowed to log in. |

Because password authentication is disabled, **at least one authorized public key is required**
for any remote login. The key(s) must belong to the device you connect *from* (the matching
private key must live there). Public keys are safe to commit.

## One-time setup steps

These are manual and are not part of `just deploy`:

1. **Deploy the config:**
   ```sh
   just deploy
   ```
2. **Authenticate this node to your tailnet** (opens a browser login; a free Tailscale
   account is sufficient):
   ```sh
   sudo tailscale up
   ```
   Optionally add `--hostname homework` for a tidy MagicDNS name.
3. **Find the tailnet address:**
   ```sh
   tailscale ip -4    # -> 100.x.y.z
   ```
4. **Add the DNS record** in Netlify DNS for `ohrg.org`:
   ```
   A  homework  ->  100.x.y.z
   ```
   (Optionally also an `AAAA` record to the `fd7a:…` Tailscale IPv6 address.)
5. **Set up each connecting device:** install Tailscale and log into the **same tailnet**.

## Connecting

From any device on the tailnet:

```sh
ssh lox@homework.ohrg.org
```

## Verification

1. On `homework`: `tailscale status` shows the node online, and `tailscale ip -4` returns the
   `100.x` address used in the DNS record.
2. From a tailnet device on a *different* physical network (e.g. a phone hotspot):
   ```sh
   dig +short homework.ohrg.org      # -> 100.x.y.z
   ssh -v lox@homework.ohrg.org      # connects and authenticates
   ```
3. Confirm SSH is **not** publicly exposed — from a host that is *not* on the tailnet:
   ```sh
   nc -vz homework.ohrg.org 22       # should time out / be refused
   ```

## Caveats and alternatives

- **Connecting key must be on the client.** An authorized key's comment (e.g. `lox@loxnix`)
  only records where it was generated. What matters is that the matching **private** key lives
  on the device you connect from. A single keypair synced across your devices is a fine setup;
  if a key's private half only exists on `homework` itself, it won't let you log in remotely.

- **Keyless auth via Tailscale SSH** (optional): `sudo tailscale up --ssh` lets the tailnet
  identity authenticate SSH, governed by an `ssh` rule in your tailnet ACL — removing the need
  to manage `authorizedKeys`. The committed key approach above is the simpler, self-contained
  default.

- **Hardening** (low urgency since SSH is no longer public): set
  `services.openssh.settings.PermitRootLogin = "no";`. If you ever switch to direct public
  exposure, also enable `services.fail2ban.enable = true;`.

- **`mosh`** (`programs.mosh.enable = true;`) gives resilient sessions over flaky/roaming links.

- **MagicDNS alternative:** skip the Netlify record entirely and connect via Tailscale's own
  name, `homework.<tailnet>.ts.net`.

- **Direct public SSH** (if you must connect from a non-Tailscale device): forward an external
  port on the router to `192.168.1.63:22` (and/or open an IPv6 inbound pinhole), then run a
  dynamic-DNS updater (e.g. `services.inadyn` / `ddclient`) to keep `A`/`AAAA homework.ohrg.org`
  current, since the ISP address and IPv6 prefix are dynamic.
