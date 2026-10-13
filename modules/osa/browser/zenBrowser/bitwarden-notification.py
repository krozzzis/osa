"""Keep the Bitwarden notification iframe transparent in Zen profiles."""

import configparser
import sys
from pathlib import Path


CSS = '''@-moz-document regexp("^moz-extension://[^/]+/notification/bar[.]html([?].*)?$") {
  html, body { background: transparent !important; }
}
'''
PREF = 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);\n'


def update_block(path: Path, name: str, content: str) -> None:
    begin = f"/* OSA {name} begin */\n"
    end = f"/* OSA {name} end */\n"
    existing = path.read_text() if path.exists() else ""
    if begin in existing and end in existing:
        prefix, remainder = existing.split(begin, 1)
        _, suffix = remainder.split(end, 1)
        existing = prefix + suffix
    if existing and not existing.endswith("\n"):
        existing += "\n"
    updated = existing + begin + content + end
    if path.exists() and path.read_text() == updated:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(updated)


def main(zen_dir: Path) -> None:
    profiles_ini = zen_dir / "profiles.ini"
    if not profiles_ini.exists():
        return
    profiles = configparser.ConfigParser()
    profiles.read(profiles_ini)
    for section in profiles.sections():
        if not section.startswith("Profile"):
            continue
        profile_name = profiles[section].get("Path")
        if not profile_name:
            continue
        profile = Path(profile_name)
        if profiles[section].getboolean("IsRelative", fallback=True):
            profile = zen_dir / profile
        if not profile.is_dir():
            continue
        update_block(profile / "chrome" / "userContent.css", "Bitwarden notification", CSS)
        update_block(profile / "user.js", "Bitwarden notification preference", PREF)


if __name__ == "__main__":
    main(Path(sys.argv[1]))
