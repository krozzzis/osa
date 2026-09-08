{ delib, lib, ... }:
let
  shortcuts = import ../../../../lib/shortcuts-translators.nix { inherit lib; };
in
delib.module {
  name = "osa.de.driftwm";

  myconfig.ifEnabled =
    { myconfig, ... }:
    {
      osa.de.driftwm.settings = {
        focus_follows_mouse = true;
        window_placement = "auto";

        session = {
          restore_bookmarks = true;
          restore_camera = true;
          restore_windows = true;
        };

        input.trackpad = {
          natural_scroll = true;
          tap_to_click = true;
        };

        snap = {
          gap = myconfig.osa.ui.gap * 1.0;
          outer_gap = myconfig.osa.ui.gap * 1.0;
        };

        decorations = {
          blur = myconfig.osa.ui.transparency < 1.0;
          corner_radius = myconfig.osa.ui.cornerRadius;
          font = myconfig.user.fonts.regular.name;
          opacity = myconfig.osa.ui.transparency;
          opacity_focused = 1.0;
        };

        keybindings = shortcuts.toDriftwmBinds { inherit myconfig; };
      };
    };
}
