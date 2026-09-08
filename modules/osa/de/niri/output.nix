{ delib, ... }:
delib.module {
  name = "osa.de.niri";

  home.ifEnabled = {
    programs.niri.settings.outputs = {

      # TODO: use denix display attributes

      # monitor = map (
      #   display:
      #   let
      #     resolution = "${toString display.width}x${toString display.height}@${toString display.refreshRate}";
      #     position = "${toString display.x}x${toString display.y}";
      #   in
      #   "${display.name},${if display.enable then "${resolution},${position},1" else "disable"}"
      # ) host.displays;

      "eDP-1" = {
        enable = true;
        mode.width = 1920;
        mode.height = 1080;
        mode.refresh = 60.0;
        position.x = 0;
        position.y = 0;
        scale = 1.0;
      };
    };
  };
}
