{ delib, ... }:
delib.module {
  name = "osa.de.dms";

  home.ifEnabled.programs.dank-material-shell.plugins = {
    dankBatteryAlerts.enable = true;
    volumeMixer.enable = true;
    dankKDEConnect.enable = true;
  };
}
