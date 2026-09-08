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
    };
}
