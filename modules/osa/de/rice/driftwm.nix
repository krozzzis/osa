{ delib, ... }:
delib.module {
  name = "osa.de.rice.driftwm";

  options = delib.singleEnableOption false;

  myconfig.ifEnabled = {
    osa = {
      de.driftwm.enable = true;
      de.dms.enable = true;
      apps.walker.enable = true;
    };
  };
}
