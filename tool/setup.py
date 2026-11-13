#!/usr/bin/env python3
"""One-time setup: generate platform folders and apply the permission patches.

Run from the monitor/ folder:   python3 tool/setup.py
Requires Flutter on PATH (https://docs.flutter.dev/get-started/install).
"""
import re
import shutil
import subprocess
import sys
from pathlib import Path

root = Path(__file__).resolve().parent.parent
flutter = shutil.which("flutter") or shutil.which("flutter.bat")
if not flutter:
    sys.exit("flutter not found on PATH")

subprocess.run(
    [flutter, "create", "--platforms=android,ios,web,windows,macos,linux",
     "--project-name", "xmrig_monitor", "--org", "app.xmrigmonitor", "."],
    cwd=root, check=True)


def patch(rel, fn):
    p = root / rel
    if not p.exists():
        print("skip (missing):", rel)
        return
    old = p.read_text(encoding="utf-8")
    new = fn(old)
    if new != old:
        p.write_text(new, encoding="utf-8")
        print("patched:", rel)
    else:
        print("already ok:", rel)


def android(t):
    if "android.permission.INTERNET" not in t:
        t = t.replace("<application", '<uses-permission android:name="android.permission.INTERNET"/>\n    <application', 1)
    if "usesCleartextTraffic" not in t:  # miners expose plain http on the LAN
        t = t.replace("<application", '<application\n        android:usesCleartextTraffic="true"', 1)
    return t


def ios(t):
    if "NSAppTransportSecurity" in t:
        return t
    extra = ("\t<key>NSAppTransportSecurity</key>\n\t<dict>\n\t\t<key>NSAllowsArbitraryLoads</key>\n\t\t<true/>\n\t</dict>\n"
             "\t<key>NSLocalNetworkUsageDescription</key>\n\t<string>Connect to your XMRig miner on the local network.</string>\n")
    i = t.rfind("</dict>")
    return t[:i] + extra + t[i:]


def mac(t):
    # Sandbox must be off to start the xmrig process; network.client for HTTP.
    t = re.sub(r"(<key>com.apple.security.app-sandbox</key>\s*)<true/>", r"\1<false/>", t)
    if "com.apple.security.network.client" not in t:
        i = t.rfind("</dict>")
        t = t[:i] + "\t<key>com.apple.security.network.client</key>\n\t<true/>\n" + t[i:]
    return t


patch("android/app/src/main/AndroidManifest.xml", android)
patch("ios/Runner/Info.plist", ios)
patch("macos/Runner/DebugProfile.entitlements", mac)
patch("macos/Runner/Release.entitlements", mac)
print("\nDone. Next: flutter pub get && flutter run -d <device>")
