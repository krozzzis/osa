{ delib, ... }:
{
  imports = [
    ((import ../../../../lib/package-module.nix) "osa.dev.mcp.playwright" (
      { pkgs }:
      delib.module {
        name = "osa.dev.mcp.playwright";

        options = delib.singleEnableOption false;

        myconfig.ifEnabled = {
          user.dev.mcp."playwright" = {
            enable = true;
            type = "local";
            command = [ "playwright-mcp" ];
          };
        };

        home.ifEnabled = {
          home.packages = [ pkgs.playwright-mcp ];
        };
      }
    ))
  ];
}
