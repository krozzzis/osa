{ delib, ... }:
delib.module {
  name = "osa.de.rice.xfce";

  options = delib.singleEnableOption false;

  myconfig.ifEnabled = {
    osa.de.xfce.enable = true;
  };
}
