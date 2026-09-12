{ delib, lib, ... }:
let
  t = import ../../../../lib/shortcuts-translators.nix { inherit lib; };
in
delib.module {
  name = "osa.de.niri";

  home.ifEnabled = { myconfig, ... }: {
    programs.niri.settings.binds = t.toNiriBinds { inherit myconfig; } // {
      "Mod+WheelScrollLeft" = {
        action."focus-column-left" = [ ];
        "cooldown-ms" = 150;
      };
      "Mod+WheelScrollRight" = {
        action."focus-column-right" = [ ];
        "cooldown-ms" = 150;
      };
      # Keep an explicit Super binding for winit compatibility; Niri maps Mod to Super.
      "Super+WheelScrollLeft" = {
        action."focus-column-left" = [ ];
        "cooldown-ms" = 150;
      };
      "Super+WheelScrollRight" = {
        action."focus-column-right" = [ ];
        "cooldown-ms" = 150;
      };
    };
  };
}
