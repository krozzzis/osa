{ delib, ... }:
delib.module {
  name = "osa.de.rice.niri";

  options = delib.singleEnableOption false;

  myconfig.ifEnabled = {
    osa = {
      de.niri.enable = true;
      de.dms.enable = true;
      apps.walker.enable = true;
    };
  };
}
