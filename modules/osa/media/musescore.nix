{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.media.musescore";

  options = { myconfig, ... }: {
    osa.media.musescore.enable = delib.boolOption myconfig.user.gui.enable;
    osa.media.musescore.pkg = delib.packageOption pkgs.musescore;
  };

  home.ifEnabled = { cfg, ... }: {
    home.packages = [
      cfg.pkg
    ];
  };
}
