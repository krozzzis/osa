{
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.editor.zed";

  options = { myconfig, ... }: {
    osa.editor.zed.enable = delib.boolOption myconfig.user.gui.enable;
    osa.editor.zed.pkg = delib.packageOption pkgs.zed-editor;
    osa.editor.zed.mimeTypes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "text/plain"
        "text/markdown"
        "text/x-markdown"
        "application/json"
        "application/ld+json"
        "application/x-yaml"
        "text/yaml"
        "text/x-yaml"
        "application/toml"
        "text/x-toml"
        "application/xml"
        "text/xml"
        "text/html"
        "text/css"
        "application/javascript"
        "text/javascript"
        "application/typescript"
        "text/x-nix"
        "application/x-sh"
      ];
      description = "MIME types opened by Zed when it is enabled";
    };
  };

  home.ifEnabled =
    { cfg, myconfig, ... }:
    let
      enabledServers = lib.filterAttrs (
        _name: server: server.enable && server.package != null
      ) myconfig.user.dev.lsp;

      zedLspConfigs = {
        "rust-analyzer" = {
          check_on_save = true;
          check.command = "clippy";
        };
        ruff = {
          format = "on";
          lint = "on";
        };
      };

      lsp = builtins.listToAttrs (
        map (name: {
          inherit name;
          value = zedLspConfigs.${name} or { };
        }) (builtins.attrNames enabledServers)
      );
    in
    {
      home.packages = with pkgs; [
        nixfmt
      ];

      programs.zed-editor = {
        enable = true;
        package = cfg.pkg;

        extensions = [
          "nix"
          "rust"
          "python"
          "toml"
        ];

        extraPackages = [
          pkgs.nixfmt
        ]
        ++ lib.mapAttrsToList (_name: server: server.package) enabledServers;

        userSettings = {
          telemetry = {
            diagnostics = false;
            metrics = false;
          };

          title_bar = {
            show_sign_in = false;
            show_branch_icon = false;
          };

          inherit lsp;

          languages = {
            Rust = {
              language_servers = [ "rust-analyzer" ];
              formatter.external.command = "rustfmt";
            };
            Python = {
              language_servers = [
                "basedpyright"
                "ruff"
              ];
              formatter.external = {
                command = "ruff";
                arguments = [ "format" ];
              };
            };
            Nix = {
              language_servers = [ "nixd" ];
              formatter.external = {
                command = "nixfmt";
              };
            };
            TOML = {
              language_servers = [ "taplo" ];
            };
          };
        };
      };

      # Keep CLI editing separate: Yazi, Git, and other terminal programs use
      # `user.editor.default` (Nixvim), whereas desktop applications open
      # these document types in the GUI editor.
      xdg.mimeApps.defaultApplications = lib.genAttrs cfg.mimeTypes (_: "dev.zed.Zed.desktop");
    };
}
