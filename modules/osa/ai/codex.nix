{
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.ai.codex";

  options = { myconfig, ... }: {
    osa.ai.codex.enable = delib.boolOption myconfig.user.gui.enable;
    osa.ai.codex.pkg = delib.packageOption pkgs.codex;
    osa.ai.codex.settings = lib.mkOption {
      type = (pkgs.formats.toml { }).type;
      default = { };
      description = "Additional Codex settings merged with OSA's MCP server configuration.";
    };
  };

  home.ifEnabled =
    { cfg, myconfig, ... }:
    let
      enabledLsp = lib.filterAttrs (
        _name: server: server.enable && server.package != null
      ) myconfig.user.dev.lsp;
      enabledMcp = lib.filterAttrs (_name: server: server.enable) myconfig.user.dev.mcp;

      mkMcpServer =
        _name: server:
        if server.type == "local" then
          {
            command = builtins.head server.command;
            args = builtins.tail server.command;
            enabled = true;
          }
        else
          {
            inherit (server) url;
            enabled = true;
          };

      mcpServers = lib.mapAttrs mkMcpServer enabledMcp;
      settings = lib.recursiveUpdate cfg.settings {
        mcp_servers = (cfg.settings.mcp_servers or { }) // mcpServers;
      };
    in
    {
      home.packages = lib.mapAttrsToList (_name: server: server.package) enabledLsp;

      programs.codex = {
        enable = true;
        package = cfg.pkg;
        inherit settings;
      };
    };
}
