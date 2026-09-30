{ delib, lib, ... }:
delib.module {
  name = "osa.de.rice.niri";

  options = delib.singleEnableOption false;

  myconfig.ifEnabled = {
    osa = {
      de.niri.enable = true;
      de.dms.enable = true;
      apps.walker.enable = true;
      fileManager.udiskie.enable = true;
    };
  };

  home.ifEnabled = { myconfig, ... }:
    lib.mkIf myconfig.osa.fileManager.udiskie.enable {
      systemd.user.services.udiskie.Unit.ConditionEnvironment = "XDG_CURRENT_DESKTOP=niri";
    };
}
