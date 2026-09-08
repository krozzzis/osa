{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.browser.librewolf";

  options = { myconfig, ... }: {
    osa.browser.librewolf.enable = delib.boolOption myconfig.user.gui.enable;
    osa.browser.librewolf.pkg = delib.packageOption pkgs.librewolf;
  };

  home.ifEnabled = {
    programs.librewolf = {
      enable = true;
    };
  };
}
