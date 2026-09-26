{ delib, ... }:
{
  imports = [
    ((import ../../../../lib/package-module.nix) "osa.dev.mcp.nixos" (
      { pkgs }:
      delib.module {
        name = "osa.dev.mcp.nixos";

        options = delib.singleEnableOption false;

        myconfig.ifEnabled = {
          user.dev.mcp."nixos" = {
            enable = true;
            type = "local";
            command = [ "mcp-nixos" ];
          };
        };

        home.ifEnabled = {
          home.packages = [ pkgs.mcp-nixos ];
        };
      }
    ))
  ];
}
