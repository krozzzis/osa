{
  delib,
  inputs,
  pkgs,
  ...
}:
delib.module {
  name = "osa.browser.zenBrowser";

  options = { myconfig, ... }: {
    osa.browser.zenBrowser.enable = delib.boolOption myconfig.user.gui.enable;
    osa.browser.zenBrowser.pkg =
      delib.packageOption
        inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default;
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
