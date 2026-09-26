{ delib, ... }:
{
  imports = [
    ((import ../../../../lib/package-module.nix) "osa.dev.lsp.nixd" (
      { pkgs }:
      delib.module {
        name = "osa.dev.lsp.nixd";

        options = delib.singleEnableOption false;

        myconfig.ifEnabled = {
          user.dev.lsp."nixd" = {
            enable = true;
            package = pkgs.nixd;
            settings = { };
          };
        };

        home.ifEnabled = {
          home.packages = [ pkgs.nixd ];
        };
      }
    ))
  ];
}
