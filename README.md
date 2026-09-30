# OSA

A reusable [denix](https://github.com/yunfachi/denix) module library for
NixOS + home-manager. This flake has no hosts, no user identity, and no
`nixosConfigurations` of its own — it's just `modules/`, meant to be
imported by whatever flake actually builds a machine.

The complete personal configuration lives in
[osa-krozzzis](https://github.com/krozzzis/osa-krozzzis): identity, profiles,
rice presets, cosmetic DMS presets and hosts. Its public composition function also lets
another flake extend or independently replace the personal and host layers.

This split is deliberate: `osa` is the reusable part anyone can depend on;
everything person- or machine-specific lives downstream.

## What's in `modules/`

Modules are grouped by category under `modules/osa/`:

| Category      | Contents                                    |
|----------------|----------------------------------------------|
| `ai/`          | AI coding assistants (claude-code, codex, opencode) |
| `apps/`        | misc applications                            |
| `browser/`     | firefox, librewolf, zen-browser, tor         |
| `de/`          | desktop environments plus base DMS/system integration |
| `dev/`         | LSP and MCP server definitions               |
| `editor/`      | nixvim, vim, zed                             |
| `fileManager/` | nautilus                                     |
| `media/`       | audio/video apps                             |
| `network/`     | yggdrasil                                    |
| `office/`      | libreoffice                                  |
| `shell/`       | CLI utilities (fish, zsh, eza, fzf, rip, ripgrep, ...) |
| `system/`      | system-level settings (audio, polkit, sddm, branding, ...) |
| `terminal/`    | wezterm                                      |

Every module is a `delib.module` (see denix), namespaced as
`myconfig.osa.<category>.<name>`. A module that needs its own flake input
declares it in a sibling `inputs.nix` (e.g.
`modules/osa/de/dms/inputs.nix`) rather than in the root flake — see
`lib/flake-inputs.nix`, which scans for these and feeds them into
`flake-file.nix`.

`flake.nix` is generated from `flake-file.nix` via
[flake-file](https://github.com/vic/flake-file) — never edit it by hand.
After touching `flake-file.nix` or any `inputs.nix`, run:

```bash
nix run .#write-flake
```

`nix flake check` fails if `flake.nix` is out of sync.

WezTerm notifications use normal urgency and the notification server's default
timeout. A downstream flake such as `osa-user` can restore WezTerm's original
behavior by setting `myconfig.osa.terminal.wezterm.notifications.autoExpire = false;`.

## OSA CLI

The `osa.system.osa-cli` module is enabled by default and installs the `osa`
command. It operates on a downstream configuration flake (by default
`~/osa-user`) and regenerates its `flake.nix` when required:

```bash
osa update
osa update-osa
osa switch nixlaptop-niri
osa update-switch nixlaptop-niri
osa update-boot --config ~/other-config my-host
osa build-iso pi-backup
osa build-installer nixlaptop-niri
osa clean
```

`switch`, `boot`, `update-switch`, and `update-boot` use systemd's interactive
`run0` privilege launcher for the `nixos-rebuild` step. The CLI also supports
being launched through privilege tools such as `sudo osa ...`, `doas osa ...`,
`run0 osa ...`, and `pkexec osa ...`. Root invocations must pass an explicit
`--config PATH`; the CLI uses that directory's owner for user-level work, while
privileged commands run directly without another authentication prompt. Extra
Nix arguments can be passed after `--`. `update-osa` updates only the downstream
flake's `osa` input. `clean` removes old Home Manager and Nix generations, then
runs the Nix garbage collector; it uses the same privilege handling for the
system-wide cleanup.

## Using OSA in your own configuration

Add it as a flake input:

```nix
inputs.osa.url = "github:krozzzis/osa";
```

A minimal composition using OSA's pinned module inputs:

```nix
{
  inputs = {
    nixpkgs.follows = "nixpkgs-stable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    denix = {
      url = "github:yunfachi/denix";
      inputs = { nixpkgs.follows = "nixpkgs"; home-manager.follows = "home-manager"; };
    };
    osa.url = "github:krozzzis/osa";
  };

  outputs = { denix, osa, ... }@inputs:
    let
      moduleInputs = osa.inputs // inputs;
      paths = [ ./hosts "${osa}/modules" ];
      scanner = import "${osa}/lib/flake-inputs.nix" { lib = inputs.nixpkgs.lib; };
    in {
      nixosConfigurations = (import "${osa}/lib/configurations.nix" {
        inputs = moduleInputs;
      }) {
        moduleSystem = "nixos";
        homeManagerUser = "<your-username>";
        inherit paths;
        exclude = scanner.findPaths paths;
        extensions = with denix.lib.extensions; [
          args
          (base.withConfig { args.enable = true; })
        ];
        specialArgs.inputs = moduleInputs;
      };
    };
}
```

For module inputs declared in your own configuration, use the `flake-file`
scanner workflow below, as `osa-user` does.

From there, a host under `./hosts/<name>/default.nix` turns modules on
via `myconfig.osa.<category>.<name>.enable = true;`.

### Required `user.*` contract

All osa modules read their user-facing knobs from the `user.*` option tree,
declared in [`modules/osa/user/default.nix`](modules/osa/user/default.nix).
Downstream flakes only *set* these options, they never declare them.
Two are mandatory and have no default:

```nix
user.constants.username = "<your-login>";
user.constants.useremail = "<your-email>";
```

Everything else (`user.gui.enable`, `user.shell.*`, `user.dev.*`, ...)
has a safe default, so a headless server can ignore it entirely. The editor
contract has two handles: `user.editor.default` is the CLI editor and defaults
to Neovim; `user.editor.gui` is the GUI editor and defaults to Zed. Each handle
is an attrset with a package in `.pkg`, and can be replaced downstream:

```nix
user.editor.default = myconfig.osa.editor.vim;
user.editor.gui = myconfig.osa.editor.zed;
```

Shell aliases are declared once and are applied to every enabled Home Manager
shell that supports `home.shellAliases` (including fish, zsh, and bash):

```nix
user.shell.aliases = {
  y = "yazi";
  v = "nvim";
};
```

See [`modules/osa/user/default.nix`](modules/osa/user/default.nix) for the full contract.

### Mutable Codex configuration

`osa.ai.codex` deliberately keeps `~/.codex/config.toml` writable because Codex
stores project trust and other runtime state there. During Home Manager
activation, OSA merges `osa.ai.codex.settings`, preserves unmanaged runtime
keys, removes settings that OSA no longer declares, and reconciles the enabled
`user.dev.mcp` servers.

### Plymouth Material theme

`osa.system.plymouth` installs the tested OSA Material theme directly from its
source repository. The configured OSA logo is passed through
`boot.plymouth.logo`, and systemd initrd support is enabled for the LUKS
password prompt. Do not add a second theme package in a downstream host: OSA
selects a single authoritative `material` package.

### Module flake inputs

Some modules need their own flake inputs (niri, DMS, walker, nixvim, ...);
each declares them in a sibling `inputs.nix` inside `${osa}/modules`. Your
flake should collect those too, using the same scanner osa itself uses
(`lib/flake-inputs.nix`) — see how
[osa-krozzzis](https://github.com/krozzzis/osa-krozzzis) does it: filter each
input root once (dropping `inputs.nix` files so denix
never imports them), then pass every collected input through to denix via
`specialArgs.inputs`.

See [osa-krozzzis](https://github.com/krozzzis/osa-krozzzis) for a real
identity/rice/host layer built this way, and its README for how to extend it
with additional user modules and hosts, or `AGENTS.md` in this repo
for the full module-authoring reference (how `delib.module`,
`nixos.ifEnabled`/`home.ifEnabled`, and cross-module options work).

Within osa itself, each module's `inputs.nix` is picked up automatically by
`lib/flake-inputs.nix`; downstream flakes need to run the same scan over
`${osa}/modules` (see the previous section) for those inputs to reach them.

### Default GUI applications

With `user.gui.enable`, OSA installs the packages selected by the typed
`user.*.default` handles (and `user.editor.gui`) and configures Home Manager's
`xdg.mimeApps`. Selecting a handle also installs its package when its module is
disabled. When Home Manager manages Zed, its wrapper supplies the executable;
OSA does not also install the unwrapped package. Use the handle's `desktop` field for desktop IDs that differ from the
executable name, such as `org.gnome.Loupe.desktop` or `zen-beta.desktop`.

Loupe is the default image viewer. Replace old `osa.apps.swayimg` references
with `osa.apps.loupe` downstream. MIME lists under `user.defaultApps.mimeTypes`
are customizable and contain concrete types, not wildcards. Enabled
LibreOffice and qBittorrent modules also provide overridable document and
torrent defaults. Existing user `mimeapps.list` files are subject to Home
Manager's usual backup policy when first adopting this configuration.

### Wine

Wine is opt-in and uses `wineWow64Packages.stable` from the selected nixpkgs
channel. Here `stable` names the Wine release flavor, not the nixpkgs channel:
`nixpkgs = "unstable"` still uses that Wine flavor from nixos-unstable.

```nix
osa.apps.wine = {
  enable = true;
  nixpkgs = "unstable";
  # pkg = pkgs.wineWow64Packages.staging;
  profiles.wine-ru = {
    prefix = ".wine-ru";
    locale = "ru_RU.UTF-8";
  };
};
```

Each profile installs a launcher named after the attribute, uses a prefix
relative to `$HOME`, and optionally sets `LANG` and `LC_ALL`. NixOS generates
the requested UTF-8 locales; standalone Home Manager needs them on the host.
The module does not initialize or migrate prefixes. The desktop launcher uses
the selected Wine package and its normal default prefix. Set
`osa.apps.wine.defaultApplication = false` to retain Wine without claiming
Windows file associations.

### WinApps

WinApps uses a Docker Windows VM. Home Manager creates its Compose and WinApps
configuration and a private, persistent Windows password. The first launch
downloads and installs Windows 11 Pro, so it can take some time. The Windows
disk is kept in the `winapps_data` Docker volume. Files in
`~/Documents/VMShared` are available to Windows through `\\host.lan\Data`.
For example:

```bash
winapps-exe ~/Documents/VMShared/SIANRG.EXE
```

`winapps-exe` creates the VM on first use, waits for RDP, then launches the
program as a RemoteApp window. WinApps stops the VM five minutes after its
last application window closes and starts it for the next launch. The VM does
not start at boot. On Wayland, RemoteApp uses XFreeRDP through XWayland; Niri
already starts `xwayland-satellite`. The Windows desktop for initial setup is
available at `http://127.0.0.1:8006` while the VM is running.

## Stable system, independently selected applications

OSA declares `nixpkgs-stable` (currently `nixos-26.05`) and
`nixpkgs-unstable` (`nixos-unstable`). Both are pinned by `flake.lock`.
Set their URLs in `flake-file.nix` / `inputs.nix` to change release versions,
then run `nix run .#write-flake` and update the corresponding lock entry.
26.11 is not a stable release yet as of September 2026. Additional inputs named
`nixpkgs-<channel>` automatically become available to all selectors. For example,
`flake-file.inputs.nixpkgs-2605.url = "github:nixos/nixpkgs/nixos-26.05"`
adds `osa.apps.rustdesk.nixpkgs = "2605"`. The `system` name is reserved.
OSA's stable/unstable input URLs are defaults that downstream can override.

In downstream denix configuration:

```nix
myconfig.always.osa = {
  system.nixpkgs = "stable";
  nixpkgs.default = "unstable";
  apps.rustdesk.nixpkgs = "stable";
  apps.wine.nixpkgs = "unstable";
  media.audacity.nixpkgs = "unstable";
  editor.zed.nixpkgs = "unstable";
  editor.nixvim.nixpkgs = "unstable";
  browser.zenBrowser.nixpkgs = "unstable";
  media.obs.nixpkgs = "stable";
  de.dms.nixpkgs = "unstable";
  de.dms.quickshell.nixpkgs = "unstable";
};
```

Application selectors accept `"stable"`, `"unstable"`, additional named inputs,
or `"system"` (the host package set, including its overlays). The default is unstable; downstream
policy can change `osa.nixpkgs.default`. Existing `.pkg` overrides win over the
selected default. The DMS greeter shares the shell and Quickshell packages
with the desktop session; Quickshell follows DMS's channel unless overridden.
Keep their channels aligned for compatible Qt plugins. OBS plugins and
Nixvim's internal package set follow their application. Channel package sets inherit the host's nixpkgs configuration
(including unfree policy), but not its overlays, preserving upstream cache
identities. A `.nixpkgs` selector changes build dependencies; applications from
separate flakes (Zen, DMS, DriftWM, etc.) retain their own pinned source
versions. Upgrade those inputs separately to update their source versions.

To support the system selector, downstream must call
`import "${inputs.osa}/lib/configurations.nix" { inherit inputs; }` instead of
`inputs.denix.lib.configurations`, with the same arguments. This builder first
reads each host's selector, then uses that channel's NixOS modules **and**
packages. Plain denix users can still select application channels, but must
choose their system nixpkgs input themselves. The builder also selects Home
Manager with the same release as the system nixpkgs: `home-manager-stable`
(`release-26.05`) for stable and `home-manager` (master) for unstable. Application
packages retain their independent channel selectors. For additional system
releases, add a matching `home-manager-<channel>` input; the builder checks its
`release.json` against nixpkgs `.version` and reports a missing match explicitly.
OSA evaluates both release combinations in its flake check. Stable Home Manager
and NixOS also support newer Fish: OSA extracts its embedded completion
generator when the old on-disk script is absent, preserving NixOS's collision
patch. The check builds both system and Home Manager completions with Fish
from both channels. Throne's TUN wrapper also follows the application's core
layout; custom `.pkg` overrides can set `.coreName` to `Core` or `ThroneCore`.
On stable NixOS, OSA also backports DNS revert authorization for TUN cores
with the existing network capabilities, avoiding an extra polkit prompt.
Niri's system portal backends use the system package set to avoid duplicate
service units when the compositor uses another channel.
`osa-user` points the root `nixpkgs` input at `nixpkgs-stable`. Its installer
builder follows each target's selected system channel.

New application modules use `lib/package-module.nix` to receive their selected
`pkgs` locally; do not add an unstable overlay to the whole system. See
`modules/osa/apps/rustdesk.nix` for a minimal example. Keep service/PAM/driver
modules compatible with the host's libraries. The oo7 integration includes a
26.05 compatibility module and builds its PAM library against the host stdenv.

Prefer release-channel packages for large applications and avoid arbitrary
`overrideAttrs` or rebuilding upstream flake packages against a different
nixpkgs without a reason. Stable reduces churn, but cannot guarantee a cache
hit. `cache.nixos.org` is the main binary cache; Cachix is only needed for
projects with their own cache. Existing OSA patches to DMS/Niri and upstream
Quickshell builds used by Caelestia can still require compilation. DMS uses the
Quickshell release from unstable by default; an explicit `quickshell.pkg`
override can select the git-flake build. Inspect a prospective update
with `nix build --dry-run` before applying it; keep the previous lock file to
return to the previous exact package set.


## Binary caches

Nix caches are configured once for the build machine, not separately for each
application or nixpkgs channel. `cache.nixos.org` serves ordinary stable and
unstable packages and is retained on hosts and installer images.

| Cache | Configuration owner |
| --- | --- |
| `https://cache.nixos.org` | NixOS defaults, all hosts/images |
| `https://niri.cachix.org` | Imported Niri NixOS module; `niri-flake.cache.enable` |
| `https://walker.cachix.org`, `https://walker-git.cachix.org` | Enabled `osa.apps.walker` |
| `https://nix-community.cachix.org` | Enabled `osa.editor.nixvim` |
| `https://winapps.cachix.org` | Enabled `osa.apps.winapps` |

The project keys come from the pinned upstream Niri module, Walker README,
Nixvim flake and WinApps README. OSA adds project caches with their public keys
and preserves signature verification. Dependency flake `nixConfig` settings do
not automatically configure the consuming system. No separate cache is
advertised by the pinned DMS, Quickshell or DriftWM inputs; avoid guessing cache
URLs or adding unrelated caches. DMS's default Quickshell comes from nixpkgs.

Inspect both configured lists (and their matching public-key lists):

```bash
nix eval --json .#nixosConfigurations.nixlaptop.config.nix.settings
nix config show | rg '^(extra-)?(substituters|trusted-public-keys)|^substitute '
nix path-info --store https://cache.nixos.org /nix/store/<exact-package-path>
nix build --dry-run .#nixosConfigurations.nixlaptop.config.system.build.toplevel
```

The first command describes the next configuration; the second describes the
Nix process doing the current build. New daemon cache settings take effect on
activation, not during evaluation. Standalone Home Manager relies on its host
administrator's daemon cache and trust configuration. Do not disable signature
checks or add users to `trusted-users` merely to use caches.

A matching URL and key do not guarantee that a particular derivation was
uploaded. Source patches, custom build flags, package-set changes and generated
application configurations can prevent hits even with the right cache enabled.
Installer images contain the target closure for offline installation; their
live environment retains NixOS's official cache.
