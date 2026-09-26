{
  delib,
  ...
}:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.browser.tor" (
      { pkgs }:
      delib.module {
        name = "osa.browser.tor";

        options = { myconfig, ... }: {
          osa.browser.tor.enable = delib.boolOption myconfig.user.gui.enable;
          osa.browser.tor.pkg = delib.packageOption (pkgs.tor-browser);
        };

        home.ifEnabled = { cfg, ... }: {
          home.packages = [ cfg.pkg ];
        };
      }
    ))
  ];
}
