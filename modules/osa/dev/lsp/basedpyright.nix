{ delib, ... }:
{
  imports = [
    ((import ../../../../lib/package-module.nix) "osa.dev.lsp.basedpyright" (
      { pkgs }:
      delib.module {
        name = "osa.dev.lsp.basedpyright";

        options = delib.singleEnableOption false;

        myconfig.ifEnabled = {
          user.dev.lsp."basedpyright" = {
            enable = true;
            package = pkgs.basedpyright;
            settings = { };
          };
        };

        home.ifEnabled = {
          home.packages = [ pkgs.basedpyright ];
        };
      }
    ))
  ];
}
