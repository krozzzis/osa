# The `user.*` interface contract.
#
# Pure option declarations -- no behavior, nothing is enabled here. Every
# consumer flake (osa-krozzzis/osa-user, your own config) sets these values;
# every `osa.*` module reads them via `myconfig.user.*`. A downstream flake
# that imports `${osa}/modules` MUST set at least:
#
#   user.constants.username
#   user.constants.useremail
#
# Everything else has a neutral default, so a headless server can ignore
# the whole gui/shell surface.
{
  delib,
  lib,
  pkgs,
  ...
}:
let
  osaTypes = import ../../../lib/types.nix { inherit lib; };

  iconThemeType = lib.types.submodule {
    options = {
      pkg = lib.mkOption {
        type = lib.types.package;
        description = "Icon theme package.";
      };
      name = lib.mkOption {
        type = lib.types.nonEmptyStr;
        description = "Icon theme name as declared by its index.theme file.";
      };
    };
  };

  lspServerSubmodule = lib.types.submodule {
    options = {
      enable = delib.description (delib.boolOption true) "Enable this LSP server";
      package = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = null;
        description = "LSP server package";
      };
      settings = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = { };
        description = "LSP server settings";
      };
    };
  };

  mcpServerSubmodule =
    lib.types.addCheck
      (lib.types.submodule {
        options = {
          enable = delib.description (delib.boolOption true) "Enable this MCP server";
          type = lib.mkOption {
            type = lib.types.enum [
              "local"
              "remote"
            ];
            description = "MCP server type";
          };
          command = lib.mkOption {
            type = lib.types.nullOr (lib.types.listOf lib.types.nonEmptyStr);
            default = null;
            description = "Command for local MCP server";
          };
          url = lib.mkOption {
            type = lib.types.nullOr lib.types.nonEmptyStr;
            default = null;
            description = "URL for remote MCP server";
          };
        };
      })
      (
        server:
        if server.type == "local" then
          server.command != null && server.command != [ ]
        else
          server.url != null
      );
in
delib.module {
  name = "user";

  options = { myconfig, ... }: {
    user.gui.enable = delib.description (delib.boolOption false) "GUI mode: enables desktop-oriented osa modules by default";

    user.gui.fonts.nerdfonts = delib.description (delib.boolOption false) "Nerd Fonts for icons in terminal and GUI prompts";

    user.fonts.regular = lib.mkOption {
      type = osaTypes.font;
      default = {
        pkg = pkgs.inter;
        name = "Inter";
      };
      description = "Regular (sans-serif) font for UI — used in GTK/Qt/Plymouth/etc.";
    };

    user.fonts.monospace = lib.mkOption {
      type = osaTypes.font;
      default = {
        pkg = pkgs.jetbrains-mono;
        name = "JetBrains Mono";
      };
      description = "Monospace font for terminals/editors — used in wezterm, editors, etc.";
    };

    user.input.keyboard.layout = lib.mkOption {
      type = lib.types.str;
      default = "us";
      description = "Global XKB layout consumed by the system and compositor adapters.";
    };

    user.input.keyboard.options = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Global comma-separated XKB options consumed by the system and compositor adapters.";
    };

    user.shell.enable = delib.description (delib.boolOption false) "Shell mode: enables CLI utility modules (eza, fzf, rip, ripgrep, ...)";

    user.shell.aliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        y = "yazi";
        v = "nvim";
      };
      description = "Aliases shared by all Home Manager shell integrations (fish, zsh, bash, etc.).";
    };

    user.shell.default =
      delib.description
        (lib.mkOption {
          type = lib.types.nullOr osaTypes.app;
          default = null;
        })
        "Default login shell as `{ pkg = <shell package>; }`; null leaves the system default. Set to e.g. `{ pkg = myconfig.osa.shell.fish.pkg; }`";

    user.constants.username = delib.description (lib.mkOption {
      type = lib.types.str;
    }) "Primary user's login name (required)";

    user.constants.useremail = delib.description (lib.mkOption {
      type = lib.types.str;
    }) "Primary user's email, used for git config (required)";

    user.editor.default = delib.description (lib.mkOption {
      type = osaTypes.app;
      default = {
        pkg = myconfig.osa.editor.nixvim.pkg;
      };
    }) "Default CLI editor handle; defaults to Neovim";

    user.editor.gui =
      delib.description
        (lib.mkOption {
          type = osaTypes.app;
          default = {
            pkg = myconfig.osa.editor.zed.pkg;
            desktop = "dev.zed.Zed.desktop";
          };
        })
        "Default GUI editor handle; defaults to Zed. Set `desktop` when its desktop-file ID differs from the package main program.";

    user.dev.lsp = lib.mkOption {
      type = lib.types.attrsOf lspServerSubmodule;
      default = { };
      description = "LSP servers exposed to editors and AI tools (populated by osa.dev.lsp.* modules)";
    };

    user.dev.mcp = lib.mkOption {
      type = lib.types.attrsOf mcpServerSubmodule;
      default = { };
      description = "MCP servers exposed to AI tools (populated by osa.dev.mcp.* modules)";
    };

    user.ui.transparency = lib.mkOption {
      type = lib.types.addCheck lib.types.float (value: value >= 0.0 && value <= 1.0);
      default = 0.95;
      description = "Global UI transparency (0.0 fully transparent, 1.0 fully opaque) used for all supported apps (DMS, etc.)";
    };

    user.ui.iconTheme = lib.mkOption {
      type = iconThemeType;
      default = {
        pkg = myconfig.osa.ui.conflux.pkg;
        name = "Conflux";
      };
      description = "Icon theme handle used by GTK applications. Defaults to Conflux.";
    };

    user.ui.cornerRadius = lib.mkOption {
      type = lib.types.ints.positive;
      default = 12;
      description = "Global window corner radius in pixels — used for DMS, niri, hyprland and other compositor window rules. Frame (outer) rounding is derived as cornerRadius + gap.";
    };

    user.ui.gap = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 8;
      description = "Global compositor gap in pixels — used for niri/hyprland layout gaps and to derive DMS frameRounding (frameRounding = cornerRadius + gap).";
    };
  };
}
