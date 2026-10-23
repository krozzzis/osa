{ delib, lib, ... }:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.ai.freebuff" (
      { pkgs }:
      delib.module {
        name = "osa.ai.freebuff";

        options = { myconfig, ... }: {
          osa.ai.freebuff.enable = delib.boolOption myconfig.user.gui.enable;
          osa.ai.freebuff.pkg = delib.packageOption (
            pkgs.callPackage ../../../packages/freebuff { }
          );
        };

        home.ifEnabled =
          { cfg, myconfig, ... }:
          let
            enabledMcp = lib.filterAttrs (_name: srv: srv.enable) myconfig.user.dev.mcp;

            # freebuff reads ~/.agents/mcp.json (standard mcpServers schema)
            # and never writes it, so the file can stay a store symlink.
            mkMcpServer =
              _name: server:
              if server.type == "local" then
                {
                  type = "stdio";
                  command = lib.head server.command;
                  args = lib.tail server.command;
                }
              else
                {
                  type = "http";
                  url = server.url;
                };

            mcpServers = lib.mapAttrs mkMcpServer enabledMcp;
          in
          {
            home.packages = [ cfg.pkg ];

            home.file.".agents/mcp.json" = lib.mkIf (mcpServers != { }) {
              text = builtins.toJSON { inherit mcpServers; };
            };
          };
      }
    ))
  ];
}
