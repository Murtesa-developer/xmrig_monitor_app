#!/usr/bin/env python3
"""Writes TERMS.md and PRIVACY.md from the texts inside the app, so the repo and the app never differ.

Run from the repository root:  python3 tool/export_legal.py
"""
import re
from pathlib import Path

root = Path(__file__).resolve().parent.parent
src = (root / "lib/features/about/legal_pages.dart").read_text(encoding="utf-8")
info = (root / "lib/core/app_info.dart").read_text(encoding="utf-8")
consts = dict(re.findall(r"const (\w+) = '([^']*)';", info))


def section(name):
    block = re.search(r"const List<\(String, String\)> %s = \[(.*?)\n\];" % name, src, re.S).group(1)
    items = []
    for m in re.finditer(r"\(\s*'((?:[^'\\]|\\.)*)',\s*((?:'(?:[^'\\]|\\.)*'\s*)+)\)", block, re.S):
        body = "".join(re.findall(r"'((?:[^'\\]|\\.)*)'", m.group(2)))
        items.append((m.group(1), body))
    return items


def fill(s):
    s = s.replace("\\'", "'")
    for k, v in consts.items():
        s = s.replace("$" + k, v)
    return s


def write(title, name, filename):
    lines = [f"# {title}", "", f"**{consts['kAppName']}** · {consts['kDeveloper']}", "",
             f"Last updated: {consts['kLegalUpdated']}", ""]
    for h, b in section(name):
        lines += [f"## {fill(h)}", "", fill(b), ""]
    (root / filename).write_text("\n".join(lines), encoding="utf-8")
    print("wrote", filename)


write("Terms of Use", "_terms", "TERMS.md")
write("Privacy Policy", "_privacy", "PRIVACY.md")
