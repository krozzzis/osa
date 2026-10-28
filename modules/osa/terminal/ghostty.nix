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
          osa.terminal.ghostty.pkg = delib.packageOption pkgs.ghostty;
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
              # Approximate WezTerm's native default: 1 cell horizontally,
              # half a cell vertically (Ghostty measures these in points).
              window-padding-x = 8;
              window-padding-y = 7;
              resize-overlay = "never";
            };
          };
        };
      }
    ))
  ];
}
