# Security Policy

## Supported versions

| Version | Supported |
|---|---|
| 1.x | Yes |
| < 1.0 | No |

## Reporting a vulnerability

**Please do not open a public issue for security problems.**

1. Use GitHub's private reporting: **Security → Report a vulnerability** on this repository.
2. If that is not available, contact the maintainer, Murtesa Developer, at: `<ADD YOUR CONTACT EMAIL HERE>`.

Please include: what you found, steps to reproduce, affected platform/version, and the impact you see.
Never include real wallet addresses, pool passwords or access tokens in a report.

This is a volunteer project, so replies are best-effort. Reports are handled privately, fixed first, and
disclosed publicly after a fix is available. Good-faith research is welcome.

## Scope

In scope: this app's code (token and config handling, storage, network requests, the local-miner launcher,
legal/About content).

Out of scope: vulnerabilities in **XMRig itself** (report to the
[XMRig project](https://github.com/xmrig/xmrig)), mining pools, wallets, Flutter/Dart packages (report
upstream), and attacks that need physical access to an unlocked device.

## Security notes for users

- **Tokens are stored on the device, unencrypted.** Node tokens, wallet and pool settings are kept in the
  app's local storage (shared preferences). Use a device lock screen and don't use the app on devices you
  don't trust.
- **Keep the miner API private.** Do not forward or expose the XMRig API port (default `44444`) to the
  internet. Use it on a trusted LAN, a VPN, or behind a TLS reverse proxy.
- **Use a long random access token** (for example `openssl rand -hex 16`). Anyone with the token and
  `--http-no-restricted` can change your miner's pool and wallet.
- **Only enable `--http-no-restricted` if you need to change config from the app.** Monitoring alone works
  with the default read-only API.
- **Plain HTTP is allowed.** XMRig serves HTTP by default, so the Android build permits cleartext traffic
  and the iOS build relaxes App Transport Security. Prefer HTTPS where you can.
- **Desktop local mode** writes `xmrig_config.json` (pool, wallet, API token) to the app's support folder and
  starts the `xmrig` program you point it at. On macOS the app sandbox is disabled so it can start a
  process. Only point it at an `xmrig` binary you built or downloaded from a source you trust.
- **Mine only on hardware and networks you own or have permission to use.**

## Disclaimer

Provided "as is" under the MIT License, without warranty. See `LICENSE`.
