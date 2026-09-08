{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.apps.swayimg";

  options = { myconfig, ... }: {
    osa.apps.swayimg.enable = delib.boolOption myconfig.user.gui.enable;
    osa.apps.swayimg.pkg = delib.packageOption pkgs.swayimg;
  };

  home.ifEnabled = { cfg, ... }: {
    home.packages = [ cfg.pkg ];
  };
}
