{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.apps.telegram";

  options = { myconfig, ... }: {
    osa.apps.telegram.enable = delib.boolOption myconfig.user.gui.enable;
  };

  nixos.ifEnabled = {
    environment.systemPackages = with pkgs; [
      telegram-desktop
    ];
  };
}
