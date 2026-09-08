{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.media.obs";

  options = { myconfig, ... }: {
    osa.media.obs.enable = delib.boolOption myconfig.user.gui.enable;
  };

  nixos.ifEnabled = {
    environment.systemPackages = with pkgs; [
      obs-studio
    ];
  };
}
