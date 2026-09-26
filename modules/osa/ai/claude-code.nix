{
  delib,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.ai.claude-code" (
      { pkgs }:
      delib.module {
        name = "osa.ai.claude-code";

        options = { myconfig, ... }: {
          osa.ai.claude-code.enable = delib.boolOption myconfig.user.gui.enable;
        };

        home.ifEnabled =
          { myconfig, ... }:
          let
            claudeBin = lib.getExe pkgs.claude-code;
            hm = inputs.home-manager.lib.hm;

            enabledLsp = lib.filterAttrs (_name: srv: srv.enable && srv.package != null) myconfig.user.dev.lsp;
            enabledMcp = lib.filterAttrs (_name: srv: srv.enable) myconfig.user.dev.mcp;

            mkMcpAdd =
              name: server:
              if server.type == "local" then
                ''
                  ${claudeBin} mcp remove --scope user ${name} >/dev/null 2>&1 || true
                  ${claudeBin} mcp add --scope user ${name} -- ${lib.escapeShellArgs server.command}
                ''
              else
                ''
                  ${claudeBin} mcp remove --scope user ${name} >/dev/null 2>&1 || true
                  ${claudeBin} mcp add --scope user --transport http ${name} ${server.url}
                '';

            mcpAddCommands = lib.mapAttrsToList mkMcpAdd enabledMcp;
          in
          {
            home.packages =
              with pkgs;
              [
                claude-code
              ]
              ++ lib.mapAttrsToList (_name: srv: srv.package) enabledLsp;

            home.activation.claudeCodeMcp = hm.dag.entryAfter [ "writeBoundary" ] (
              lib.concatStringsSep "\n" mcpAddCommands
            );
          };
      }
    ))
  ];
}
