{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.media.qbittorrent";

  options = { myconfig, ... }: {
    osa.media.qbittorrent.enable = delib.boolOption myconfig.user.gui.enable;
  };

  home.ifEnabled = {
    home.packages = with pkgs; [
      qbittorrent
    ];
  };
}
