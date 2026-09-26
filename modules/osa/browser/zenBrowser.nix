{
  delib,
  inputs,
  ...
}:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.browser.zenBrowser" (
      { pkgs }:
      delib.module {
        name = "osa.browser.zenBrowser";

        options = { myconfig, ... }: {
          osa.browser.zenBrowser.enable = delib.boolOption myconfig.user.gui.enable;
          osa.browser.zenBrowser.desktop = delib.strOption "zen-beta.desktop";
          osa.browser.zenBrowser.pkg =
            delib.packageOption
              (import inputs.zen-browser { inherit pkgs; }).default;
        };

        nixos.ifEnabled = {
          environment.sessionVariables = {
            MOZ_USE_XINPUT2 = "1";
          };
        };

        home.ifEnabled = { cfg, ... }: {
          home.packages = [ cfg.pkg ];
        };
      }
    ))
  ];
}
