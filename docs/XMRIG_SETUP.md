# Using XMRig with XMRig Monitor

The app reads status from XMRig's built-in HTTP API (`GET /2/summary`) and can change settings through
`PUT /1/config`. No XMRig changes are needed — only turn the API on.

## 1. Build XMRig (Linux)

```bash
sudo apt install -y build-essential cmake libuv1-dev libssl-dev libhwloc-dev
git clone https://github.com/xmrig/xmrig.git && cd xmrig
mkdir build && cd build && cmake .. -DCMAKE_BUILD_TYPE=Release && make -j"$(nproc)"
```

## 2. Start it with the API enabled

Any `--http-*` flag turns the API on.

```bash
TOKEN="$(openssl rand -hex 16)"      # keep this secret; you type it into the app

./xmrig \
  --url=<POOL_HOST>:<POOL_PORT> \
  --user=<YOUR_WALLET_ADDRESS> \
  --pass=x \
  --http-host=127.0.0.1 \
  --http-port=44444 \
  --http-access-token="$TOKEN" \
  --http-no-restricted          # optional: lets the app change config
```

| Flag | Meaning |
|---|---|
| `--http-host` | `127.0.0.1` = this computer only. Use the machine's LAN IP (or `0.0.0.0`) to monitor from a phone. |
| `--http-port` | API port (the app defaults to `44444`). |
| `--http-access-token` | Secret the app sends as a Bearer token. |
| `--http-no-restricted` | Allow config changes (`PUT /1/config`). Needs a token. Leave out for read-only monitoring. |

Same thing in `config.json`:

```json
"http": {
  "enabled": true,
  "host": "127.0.0.1",
  "port": 44444,
  "access-token": "long-random-secret",
  "restricted": false
}
```

### Low-resource mining example

```bash
./xmrig ... --threads=1 --cpu-priority=0 --randomx-mode=light --pause-on-active=60
```

## 3. Connect the app

Add a node: **IP/host**, **port**, **token**. Use `127.0.0.1` when the app runs on the same computer.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| "Cannot reach node" | Wrong IP/port, firewall blocks the port, or `--http-host` is `127.0.0.1` but you connect from another device. |
| "Access token rejected" | Token in the app differs from `--http-access-token`. |
| Config tab: "pool data could not be loaded" | Node is read-only. Start with `--http-no-restricted` and a token. |
| "Online · not connected to pool" | Wrong pool address/port/TLS, wallet rejected, or no internet on the miner. |
| Web build can't reach a node | An `https://` page can't call plain `http://` (mixed content). |

## Safety

Never expose the API port to the internet. See `SECURITY.md`.
