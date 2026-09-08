{ delib, lib, ... }:
delib.module {
  name = "osa.de.dms";

  myconfig.ifEnabled =
    { myconfig, ... }:
    lib.mkIf myconfig.osa.de.driftwm.enable {
      osa.de.driftwm.settings.keybindings = {
        "mod+b" = "spawn dms ipc call bar toggle index 0";
        "mod+shift+p" = "spawn dms ipc call spotlight toggle";
        "mod+space" = "spawn dms ipc call spotlight toggle";
        "mod+n" = "spawn dms ipc call notifications toggle";
        "mod+comma" = "spawn dms ipc call settings toggle";
        "mod+x" = "spawn dms ipc call powermenu toggle";
        "mod+v" = "spawn dms ipc call clipboard toggle";
        "super+alt+l" = "spawn dms ipc call lock lock";
        "XF86AudioRaiseVolume" = "spawn dms ipc call audio increment 3";
        "XF86AudioLowerVolume" = "spawn dms ipc call audio decrement 3";
        "XF86AudioMute" = "spawn dms ipc call audio mute";
        "XF86AudioMicMute" = "spawn dms ipc call audio micmute";
        "XF86MonBrightnessUp" = "spawn dms ipc call brightness increment 5 ''";
        "XF86MonBrightnessDown" = "spawn dms ipc call brightness decrement 5 ''";
      };
    };
}
