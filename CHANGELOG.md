# Changelog

## 1.1.0

- Shares accepted: total and per worker, rejected count, accept rate and time since the last accepted share.
- `TERMS.md` and `PRIVACY.md` added to the repository (generated from the in-app text with `python3 tool/export_legal.py`).

## 1.0.0

- Monitor many XMRig nodes: total hashrate, per-worker status, pool connection, shares, uptime.
- Login by node IP/host, port and access token; add, edit and remove nodes.
- Config: choose a node, load its pool settings, edit and send them (`PUT /1/config`), raw JSON editor.
- Desktop: start xmrig from the app with live console output; connection events on every platform.
- Android, iOS, web, Windows, macOS and Linux from one Flutter codebase; light and dark themes.
- About page, Terms of Use and Privacy Policy.
