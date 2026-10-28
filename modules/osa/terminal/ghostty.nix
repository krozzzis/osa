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
              background-blur = true;
              font-family = myconfig.user.fonts.monospace.name;
            };
          };
        };
      }
    ))
  ];
}
