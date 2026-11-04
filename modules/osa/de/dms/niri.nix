{ delib, lib, ... }:
delib.module {
  name = "osa.de.dms";

  home.ifEnabled =
    { myconfig, ... }:
    lib.mkIf myconfig.osa.de.niri.enable {
      programs.dank-material-shell.niri.includes.enable = true;
      programs.niri.settings.binds = {
        "Mod+B" = {
          hotkey-overlay.title = "Toggle Bar Visibility";
          action.spawn = [
            "dms"
            "ipc"
            "call"
            "bar"
            "toggle"
            "index"
            "0"
          ];
        };
      };
    };
}
