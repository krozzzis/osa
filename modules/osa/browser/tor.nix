{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.browser.tor";

  options = { myconfig, ... }: {
    osa.browser.tor.enable = delib.boolOption myconfig.user.gui.enable;
    osa.browser.tor.pkg = delib.packageOption (pkgs.tor-browser);
  };

  home.ifEnabled = {
    home.packages = with pkgs; [
      tor-browser
    ];
  };
}
