{ delib, lib, ... }:
let
  t = import ../../../../lib/shortcuts-translators.nix { inherit lib; };
  workspaceKeys = [
    "1"
    "2"
    "3"
    "4"
    "5"
    "6"
    "7"
    "8"
    "9"
    "0"
  ];
in
delib.module {
  name = "osa.de.niri";

  home.ifEnabled =
    { myconfig, ... }:
    let
      workspaceBinds = lib.listToAttrs (
        lib.concatLists (
          lib.imap0 (index: workspace: [
            {
              name = "Mod+${builtins.elemAt workspaceKeys index}";
              value.action.focus-workspace = workspace;
            }
            {
              name = "Mod+Shift+${builtins.elemAt workspaceKeys index}";
              value.action.move-column-to-workspace = workspace;
            }
          ]) myconfig.user.ui.workspaces
        )
      );
    in
    {
      programs.niri.settings.binds =
        t.toNiriBinds { inherit myconfig; }
        // workspaceBinds
        // {
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
