# XMRig Monitor

A Flutter app to **monitor and configure many [XMRig](https://github.com/xmrig/xmrig) miners** from one
place — Android, iOS, web, Windows, macOS and Linux from a single codebase.

> Developed by **Murtesa Developer** · MIT License · Use at your own risk (see `LICENSE`, `SECURITY.md`).

## Features

- **Many nodes:** add any number of miners by IP/host, port and token.
- **Dashboard:** total hashrate across all nodes, plus a card per worker (status, pool, ping, shares, uptime, version).
- **Accepted work:** shares accepted / rejected, accept rate and last-share time, per worker and in total.
- **Connection state:** clearly shows *Connected to pool* / *Online but not connected* / *Cannot reach node*.
- **Config:** pick a node, see its pool settings, change them and send them back (or edit raw JSON).
- **Logs:** live xmrig console output on desktop (when the app starts xmrig) and connection events everywhere.
- **Desktop local mode:** start xmrig from the app with a generated config.
- Light and dark themes, responsive layout (bottom bar on phones, side rail on desktop).

## Quick start

```bash
git clone <this-repo> && cd xmrig-monitor
python3 tool/setup.py      # runs `flutter create` for all platforms + permission patches
flutter pub get
flutter run -d linux       # or windows / macos / chrome / <phone>
flutter build apk --release
```

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install). Then enable XMRig's HTTP API —
see [`docs/XMRIG_SETUP.md`](docs/XMRIG_SETUP.md).

## How it works

XMRig has an HTTP API (`GET /2/summary`, `GET/PUT /1/config`) but **no log endpoint**. So:

| Where | Pool connected / not | Logs |
|---|---|---|
| Desktop, app starts xmrig | API + parsed console output | real xmrig output |
| Any platform, remote node | API (`connection.pool`, `uptime`) | event log from API changes |

## Project structure

```
lib/
  main.dart, app.dart
  core/       design system: theme, shared widgets, formatting
  data/       models + services (API client, config builder, log parser, local miner, storage)
  state/      monitor_controller.dart
  features/   shell, dashboard, nodes, logs, config, about, onboarding
tool/setup.py generates platform folders and applies permission patches
```

## Legal

[Terms of Use](TERMS.md) · [Privacy Policy](PRIVACY.md) — the same text is shown in the app (About tab).

## Security

Read [`SECURITY.md`](SECURITY.md) before exposing a miner API. Report vulnerabilities privately.

## License

[MIT](LICENSE) © 2026 Murtesa Developer. XMRig is a separate GPL-3.0 project — see [`NOTICE.md`](NOTICE.md).
