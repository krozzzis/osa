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
  # Editor handles are usually complete `osa.editor.*` module attrsets. Keep
  # their extra fields (`enable`, settings, …), while enforcing the one field
  # every consumer relies on.
  defaultAppType = lib.types.addCheck lib.types.attrs (
    app: app ? pkg && lib.types.package.check app.pkg
  );

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
            type = lib.types.nullOr (lib.types.listOf lib.types.str);
            default = null;
            description = "Command for local MCP server";
          };
          url = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
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
      type = lib.types.attrs;
      default = {
        pkg = pkgs.inter;
        name = "Inter";
      };
      description = "Regular (sans-serif) font for UI — used in GTK/Qt/Plymouth/etc.";
    };

    user.fonts.monospace = lib.mkOption {
      type = lib.types.attrs;
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

    user.shell.default =
      delib.description
        (lib.mkOption {
          type = lib.types.nullOr lib.types.attrs;
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
      type = defaultAppType;
      default = {
        pkg = myconfig.osa.editor.nixvim.pkg;
      };
    }) "Default CLI editor handle; defaults to Neovim";

    user.editor.gui = delib.description (lib.mkOption {
      type = defaultAppType;
      default = {
        pkg = myconfig.osa.editor.zed.pkg;
      };
    }) "Default GUI editor handle; defaults to Zed";

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
      type = lib.types.float;
      default = 0.95;
      description = "Global UI transparency (0.0 fully transparent, 1.0 fully opaque) used for all supported apps (DMS, etc.)";
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
