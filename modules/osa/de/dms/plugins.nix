{ delib, pkgs, ... }:
delib.module {
  name = "osa.de.dms";

  home.ifEnabled = {
    home.packages = [
      pkgs.libnotify
      pkgs.libsecret
    ];

    programs.dank-material-shell.plugins = {
      dankBatteryAlerts.enable = true;
      dankCalendar.enable = true;
      volumeMixer.enable = true;
      dankKDEConnect.enable = true;
    };
  };
}
