{
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.de.dms";

  myconfig.ifEnabled.osa = {
    system.polkit.agent.enable = false;
    de.dms.settings.lockPamPath = lib.mkDefault "/etc/pam.d/dankshell";
  };

  nixos.ifEnabled = {
    services = {
      upower.enable = true;
      power-profiles-daemon.enable = lib.mkDefault true;
      geoclue2.enable = lib.mkDefault true;
      dbus.packages = [ pkgs.cups-pk-helper ];
    };
    security.polkit.enable = lib.mkDefault true;
    security.pam.services.dankshell = {
      oo7.enable = true;
      rules.auth.oo7.settings.unlock = true;
    };
    environment.systemPackages = with pkgs; [
      libappindicator
      upower
      cups-pk-helper
      seahorse
      xdg-terminal-exec
    ];
  };
}
