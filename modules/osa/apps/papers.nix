{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.apps.papers";

  options = { myconfig, ... }: {
    osa.apps.papers.enable = delib.boolOption myconfig.user.gui.enable;
    osa.apps.papers.desktop = delib.strOption "org.gnome.Papers.desktop";
    osa.apps.papers.pkg = delib.packageOption pkgs.papers;
  };

  home.ifEnabled = { cfg, ... }: {
    home.packages = [ cfg.pkg ];
  };
}
