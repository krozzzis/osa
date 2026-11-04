{ delib, ... }:
delib.module {
  name = "osa.de.niri";

  home.ifEnabled = { myconfig, ... }: {
    programs.niri.settings = {
      input = {
        keyboard.xkb = {
          inherit (myconfig.user.input.keyboard) layout;

          options = builtins.concatStringsSep ","
            (builtins.filter (s: s != "") [
              (myconfig.user.input.keyboard.options or "")
              "compose:ralt"
            ]);
        };

        touchpad = {
          tap = true;
          natural-scroll = true;
          # accel-speed 0.2
          # accel-profile "flat"
          # scroll-factor 1.0
          # scroll-factor vertical=1.0 horizontal=-2.0
          # scroll-method "two-finger"
          # scroll-button 273
          # scroll-button-lock
          # tap-button-map "left-middle-right"
          # click-method "clickfinger"
          # left-handed
          # disabled-on-external-mouse
          middle-emulation = true;
        };
      };

      layout.border.enable = false;

      gestures = {
        hot-corners.enable = false;
      };
    };
  };
}
