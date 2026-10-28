{ delib, ... }:
delib.module {
  name = "osa.de.niri";

  home.ifEnabled = { myconfig, ... }: {
    programs.niri.settings.window-rules =
      let
        r = myconfig.osa.ui.cornerRadius * 1.0;
      in
      [
        {
          matches = [
            { app-id = "^org\\.wezfurlong\\.wezterm$"; }
            { app-id = "^com\\.mitchellh\\.ghostty$"; }
          ];
          # The terminal supplies window opacity; remove its opaque border so
          # compositor blur remains visible at the window edge.
          draw-border-with-background = false;
          background-effect.blur = true;
          geometry-corner-radius = {
            top-left = r;
            top-right = r;
            bottom-left = r;
            bottom-right = r;
          };
          clip-to-geometry = true;
        }
      ];
  };
}
