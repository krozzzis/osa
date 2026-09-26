{
  delib,
  ...
}:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.browser.librewolf" (
      { pkgs }:
      delib.module {
        name = "osa.browser.librewolf";

        options = { myconfig, ... }: {
          osa.browser.librewolf.enable = delib.boolOption myconfig.user.gui.enable;
          osa.browser.librewolf.pkg = delib.packageOption pkgs.librewolf;
        };

        home.ifEnabled = { cfg, ... }: {
          programs.librewolf = {
            package = cfg.pkg;
            enable = true;
          };
        };
      }
    ))
  ];
}
