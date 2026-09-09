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

## OSA CLI

The `osa.system.osa-cli` module is enabled by default and installs the `osa`
command. It operates on a downstream configuration flake (by default
`~/osa-user`) and regenerates its `flake.nix` when required:

```bash
osa update
osa switch nixlaptop-niri
osa update-switch nixlaptop-niri
osa update-boot --config ~/other-config my-host
osa build-iso pi-backup
osa build-installer nixlaptop-niri
```

`switch`, `boot`, `update-switch`, and `update-boot` use systemd's interactive
`run0` privilege launcher for the `nixos-rebuild` step. Extra Nix arguments can
be passed after `--`.

## Using OSA in your own configuration

Add it as a flake input:

```nix
inputs.osa.url = "github:krozzzis/osa";
```

Then feed `${inputs.osa}/modules` into denix's module scan alongside your
own module/host directories. A minimal flake putting this together:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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

  outputs = { denix, osa, ... }@inputs: {
    nixosConfigurations = denix.lib.configurations {
      moduleSystem = "nixos";
      homeManagerUser = "<your-username>";
      paths = [
        ./hosts
        "${osa}/modules"
      ];
      specialArgs = { inherit inputs; };
    };
  };
}
```

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

See the table in `AGENTS.md` for the full contract.

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
