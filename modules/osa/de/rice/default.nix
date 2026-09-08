{ delib, lib, ... }:
delib.module {
  name = "osa.de.rice";

  options = {
    osa.de.rice.primary = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "niri"
          "caelestia"
          "xfce"
        ]
      );
      default = null;
      description = "Primary enabled OSA rice; used as the display manager's default session.";
    };
  };

  myconfig.always =
    { myconfig, ... }:
    let
      anyEnabled = lib.any (name: myconfig.osa.de.rice.${name}.enable) [
        "niri"
        "caelestia"
        "xfce"
      ];
    in
    lib.mkIf anyEnabled {
      user.gui.enable = true;
      user.shell.enable = true;
    };

  nixos.always =
    { myconfig, ... }:
    let
      rice = myconfig.osa.de.rice;
      names = [
        "niri"
        "caelestia"
        "xfce"
      ];
      enabled = lib.filter (name: rice.${name}.enable) names;
      primaryEnabled = rice.primary != null && rice.${rice.primary}.enable;
      sessions = {
        niri = "niri";
        caelestia = "hyprland";
        xfce = "xfce";
      };
    in
    lib.mkIf (enabled != [ ]) {
      assertions = [
        {
          assertion = rice.primary != null;
          message = "At least one OSA rice is enabled, so osa.de.rice.primary must be set.";
        }
        {
          assertion = primaryEnabled;
          message = "osa.de.rice.primary must name an enabled OSA rice.";
        }
      ];

      services.displayManager.defaultSession = lib.mkIf primaryEnabled sessions.${rice.primary};
    };
}
