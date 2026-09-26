{ delib, ... }:
{
  imports = [
    ((import ../../../../lib/package-module.nix) "osa.dev.lsp.taplo" (
      { pkgs }:
      delib.module {
        name = "osa.dev.lsp.taplo";

        options = delib.singleEnableOption false;

        myconfig.ifEnabled = {
          user.dev.lsp."taplo" = {
            enable = true;
            package = pkgs.taplo;
            settings = { };
          };
        };

        home.ifEnabled = {
          home.packages = [ pkgs.taplo ];
        };
      }
    ))
  ];
}
