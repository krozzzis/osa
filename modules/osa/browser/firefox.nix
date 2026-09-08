{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.browser.firefox";

  options = { myconfig, ... }: {
    osa.browser.firefox.enable = delib.boolOption myconfig.user.gui.enable;
    osa.browser.firefox.pkg = delib.packageOption pkgs.firefox;
  };

  home.ifEnabled = {
    programs.firefox = {
      enable = true;
    };
  };
}
