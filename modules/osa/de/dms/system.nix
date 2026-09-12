{
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.de.dms";

  myconfig.ifEnabled.osa.system.polkit.agent.enable = false;

  nixos.ifEnabled = {
    services = {
      upower.enable = true;
      power-profiles-daemon.enable = lib.mkDefault true;
      geoclue2.enable = lib.mkDefault true;
      dbus.packages = [ pkgs.cups-pk-helper ];
    };
    security.polkit.enable = lib.mkDefault true;
    environment.systemPackages = with pkgs; [
      libappindicator
      upower
      cups-pk-helper
      seahorse
    ];
  };
}
