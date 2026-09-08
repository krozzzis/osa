{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.apps.arduinoIde";

  options = { myconfig, ... }: {
    osa.apps.arduinoIde.enable = delib.boolOption myconfig.user.gui.enable;
    osa.apps.arduinoIde.pkg = delib.packageOption (pkgs.arduino-ide);
  };

  home.ifEnabled = { cfg, ... }: {
    home.packages = [
      cfg.pkg
      pkgs.python3
    ];
  };

  nixos.ifEnabled = { myconfig, ... }: {
    users.users.${myconfig.user.constants.username}.extraGroups = [ "dialout" ];
  };
}
