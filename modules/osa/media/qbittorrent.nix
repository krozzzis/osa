{
  delib,
  pkgs,
  lib,
  ...
}:
delib.module {
  name = "osa.media.qbittorrent";

  options = { myconfig, ... }: {
    osa.media.qbittorrent.pkg = delib.packageOption pkgs.qbittorrent;
    osa.media.qbittorrent.enable = delib.boolOption myconfig.user.gui.enable;
  };

  home.ifEnabled = { cfg, ... }: {
    home.packages = [ cfg.pkg ];
    xdg.mimeApps = {
      enable = true;
      defaultApplications = lib.genAttrs [ "application/x-bittorrent" "x-scheme-handler/magnet" ] (
        _: lib.mkDefault [ "org.qbittorrent.qBittorrent.desktop" ]
      );
    };
  };
}
