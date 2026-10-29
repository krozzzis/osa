{ delib, ... }:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.terminal.ghostty" (
      { pkgs }:
      delib.module {
        name = "osa.terminal.ghostty";

        options = { myconfig, ... }: {
          osa.terminal.ghostty.enable = delib.boolOption myconfig.user.gui.enable;
          osa.terminal.ghostty.desktop = delib.strOption "com.mitchellh.ghostty.desktop";
          osa.terminal.ghostty.pkg = delib.packageOption (
            pkgs.ghostty.overrideAttrs (old: {
              # Preserve UTF-8 notifications and allow Y/N in GTK close dialogs.
              patches = (old.patches or [ ]) ++ [ ./ghostty-notification-utf8.patch ];
            })
          );
        };

        home.ifEnabled = { cfg, myconfig, ... }: {
          programs.ghostty = {
            enable = true;
            package = cfg.pkg;
            settings = {
              background-opacity = myconfig.osa.ui.transparency;
              # Match WezTerm's text_background_opacity = 1.0: cell backgrounds
              # stay opaque even while the window background is translucent.
              background-opacity-cells = false;
              # Keep dim (faint) foreground text fully opaque as well.
              faint-opacity = 1.0;
              background-blur = true;
              font-family = myconfig.user.fonts.monospace.name;
              # WezTerm's native default is one cell of horizontal padding and
              # half a cell vertically. At 12pt a cell is roughly 9.6x21px,
              # i.e. ~7.2pt horizontally and ~7.9pt vertically, so the
              # vertical padding ends up slightly larger. Ghostty measures
              # these in points.
              window-padding-x = 7;
              window-padding-y = 8;
              resize-overlay = "never";
            };
          };
        };
      }
    ))
  ];
}
