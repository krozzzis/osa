{ delib, ... }:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.apps.rustdesk" (
      { pkgs }:
      delib.module {
        name = "osa.apps.rustdesk";
        options = {
          osa.apps.rustdesk = {
            enable = delib.boolOption false;
            pkg = delib.packageOption pkgs.rustdesk-flutter;
          };
        };
        home.ifEnabled = { cfg, ... }: { home.packages = [ cfg.pkg ]; };
      }
    ))
  ];
}
