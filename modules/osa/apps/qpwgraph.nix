{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.apps.qpwgraph";

  options = { myconfig, ... }: {
    osa.apps.qpwgraph.enable = delib.boolOption myconfig.user.gui.enable;
    osa.apps.qpwgraph.pkg = delib.packageOption pkgs.qpwgraph;
  };

  home.ifEnabled = { cfg, ... }: {
    home.packages = [ cfg.pkg ];
  };
}
