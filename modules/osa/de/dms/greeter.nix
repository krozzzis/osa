{ delib, lib, ... }:
delib.module {
  name = "osa.de.dms.greeter";

  options = { myconfig, ... }: {
    osa.de.dms.greeter.enable = delib.boolOption myconfig.osa.de.dms.enable;
  };

  myconfig.ifEnabled.osa.system.oo7.enable = true;

  nixos.ifEnabled = { myconfig, ... }: {
    services = {
      displayManager.dms-greeter = {
        enable = true;
        package = myconfig.osa.de.dms.pkg;
        quickshell.package = myconfig.osa.de.dms.quickshell.pkg;
        compositor.name = "niri";
        configHome = "/home/${myconfig.user.constants.username}";
      };
      greetd.greeterManagesPlymouth = false;
      accounts-daemon.enable = true;
      power-profiles-daemon.enable = lib.mkDefault true;
    };
    security.polkit.enable = lib.mkDefault true;
    security.pam.services.dms-greeter.oo7.enable = true;
  };
}
