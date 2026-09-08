{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.media.vlc";

  options = { myconfig, ... }: {
    osa.media.vlc.enable = delib.boolOption myconfig.user.gui.enable;
    osa.media.vlc.pkg = delib.packageOption pkgs.vlc;
  };

  nixos.ifEnabled = { myconfig, ... }: {
    environment.systemPackages = [
      myconfig.osa.media.vlc.pkg
    ];
  };
}
