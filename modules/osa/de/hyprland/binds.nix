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
  name = "osa.de.hyprland";

  home.ifEnabled = { myconfig, ... }: {
    wayland.windowManager.hyprland.settings = {
      "$mod" = "SUPER";
      bind =
        t.toHyprlandBindsList { inherit myconfig; }
        ++ lib.concatLists (
          lib.imap0 (index: workspace: [
            "$mod, ${builtins.elemAt workspaceKeys index}, workspace, name:${workspace}"
            "$mod SHIFT, ${builtins.elemAt workspaceKeys index}, movetoworkspace, name:${workspace}"
          ]) myconfig.user.ui.workspaces
        );
      workspace = map (workspace: "name:${workspace}, persistent:true") myconfig.user.ui.workspaces;
    };
  };
}
