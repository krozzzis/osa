{ delib, ... }:
delib.module {
  name = "osa.de.rice.caelestia";

  options = delib.singleEnableOption false;

  myconfig.ifEnabled = {
    osa = {
      de.hyprland.enable = true;
      de.caelestia.enable = true;
      apps.polkitLxqtAgent.enable = true;
    };
  };
}
