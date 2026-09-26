{
  delib,
  ...
}:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.apps.loupe" (
      { pkgs }:
      delib.module {
        name = "osa.apps.loupe";

        options = { myconfig, ... }: {
          osa.apps.loupe.enable = delib.boolOption myconfig.user.gui.enable;
          osa.apps.loupe.desktop = delib.strOption "org.gnome.Loupe.desktop";
          osa.apps.loupe.pkg = delib.packageOption pkgs.loupe;
        };

        home.ifEnabled = { cfg, ... }: {
          home.packages = [ cfg.pkg ];
        };
      }
    ))
  ];
}
