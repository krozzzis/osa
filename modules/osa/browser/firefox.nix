{
  delib,
  ...
}:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.browser.firefox" (
      { pkgs }:
      delib.module {
        name = "osa.browser.firefox";

        options = { myconfig, ... }: {
          osa.browser.firefox.enable = delib.boolOption myconfig.user.gui.enable;
          osa.browser.firefox.pkg = delib.packageOption pkgs.firefox;
        };

        home.ifEnabled = { cfg, ... }: {
          programs.firefox = {
            package = cfg.pkg;
            enable = true;
          };
        };
      }
    ))
  ];
}
