{
  delib,
  lib,
  pkgs,
  inputs,
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
      codexBin = lib.getExe cfg.pkg;
      hm = inputs.home-manager.lib.hm;

      enabledLsp = lib.filterAttrs (
        _name: server: server.enable && server.package != null
      ) myconfig.user.dev.lsp;
      enabledMcp = lib.filterAttrs (_name: server: server.enable) myconfig.user.dev.mcp;

      mkMcpAdd =
        name: server:
        if server.type == "local" then
          ''
            ${codexBin} mcp remove ${name} >/dev/null 2>&1 || true
            ${codexBin} mcp add ${name} -- ${lib.escapeShellArgs server.command}
          ''
        else
          ''
            ${codexBin} mcp remove ${name} >/dev/null 2>&1 || true
            ${codexBin} mcp add ${name} --url ${server.url}
          '';

      mcpAddCommands = lib.mapAttrsToList mkMcpAdd enabledMcp;
    in
    {
      home.packages = lib.mapAttrsToList (_name: server: server.package) enabledLsp;

      # Don't manage config.toml via home-manager — it creates a read-only
      # symlink to the Nix store, which prevents codex from persisting trust
      # and other runtime settings.  MCP servers are configured via CLI
      # in activation scripts instead (same pattern as claude-code.nix).
      programs.codex = {
        enable = true;
        package = cfg.pkg;
        settings = lib.mkForce null;
      };

      home.activation.codexMcp = hm.dag.entryAfter [ "writeBoundary" ] (
        lib.concatStringsSep "\n" mcpAddCommands
      );
    };
}
