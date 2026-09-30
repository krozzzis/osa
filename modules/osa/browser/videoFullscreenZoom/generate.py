#!/usr/bin/env python3
"""Regenerate and verify Tampermonkey's deterministic provisioning document."""

import argparse
import base64
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parent
SCRIPT = ROOT / "zoom.user.js"
DOCUMENT = ROOT / "provisioning.json"
HASH = ROOT / "provisioning-hash.txt"


def tm_hash(value):
    """Tampermonkey 5.6 jsonImport hash v1 (recursive SHA-256)."""
    if isinstance(value, dict):
        value = "".join(tm_hash(item) for _, item in sorted(value.items()))
    elif isinstance(value, list):
        value = "".join(tm_hash(item) for item in value)
    elif value is None:
        value = "object:null"
    elif isinstance(value, bool):
        value = f"boolean:{str(value).lower()}"
    elif isinstance(value, (int, float)):
        value = f"number:{value}"
    else:
        value = f"string:{value}"
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    document = {
        "version": "1",
        "settings": {"runtime_content_mode": "userscripts"},
        "scripts": [{
            "name": "OSA Video Fullscreen Zoom",
            "enabled": True,
            "position": 1,
            "source": base64.b64encode(SCRIPT.read_bytes()).decode("ascii"),
        }],
    }
    # Tampermonkey 5.6 imports a new script when this hash changes; migrate
    # existing profiles before shipping a changed provisioning document.
    contents = json.dumps(document, separators=(",", ":"), ensure_ascii=False) + "\n"
    digest = "1:" + tm_hash(document) + "\n"
    if args.check:
        if DOCUMENT.read_text() != contents or HASH.read_text() != digest:
            parser.error("Tampermonkey provisioning files are stale; run generate.py")
    else:
        DOCUMENT.write_text(contents)
        HASH.write_text(digest)


if __name__ == "__main__":
    main()
