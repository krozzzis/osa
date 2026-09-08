{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.media.kdenlive";

  options = { myconfig, ... }: {
    osa.media.kdenlive.enable = delib.boolOption myconfig.user.gui.enable;
    osa.media.kdenlive.pkg = delib.packageOption pkgs.kdePackages.kdenlive;
  };

  home.ifEnabled = { cfg, ... }: {
    home.packages = [
      cfg.pkg
    ];
  };
}
