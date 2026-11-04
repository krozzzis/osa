{ lib }:
let
  inherit (builtins)
    filter
    map
    listToAttrs
    attrNames
    attrValues
    head
    isList
    isInt
    ;

  # -- Niri translator --

  toNiriBind = s: {
    name = if s.mod == [ ] then s.key else "${lib.concatStringsSep "+" s.mod}+${s.key}";
    value = {
      action = s.action;
    }
    // lib.optionalAttrs (s.title != null) {
      hotkey-overlay = {
        title = s.title;
      };
    }
    // lib.optionalAttrs (s.cooldownMs != null) { "cooldown-ms" = s.cooldownMs; };
  };

  toNiriBinds =
    { myconfig }:
    listToAttrs (map toNiriBind (filter (s: s.enable) (myconfig.user.shortcuts or [ ])));

  # -- Hyprland translator --

  modMap = {
    Mod = "SUPER";
    Ctrl = "CONTROL";
    Shift = "SHIFT";
    Alt = "ALT";
  };

  toHyprMod =
    mods: lib.concatStringsSep " " (map (m: modMap.${m} or (throw "unknown modifier: ${m}")) mods);

  niriToHyprDispatcher = {
    close-window = "killactive";
    spawn = "exec";
    focus-column-left = "movefocus l";
    focus-column-right = "movefocus r";
    focus-window-or-workspace-down = "movefocus d";
    focus-window-or-workspace-up = "movefocus u";
    move-column-left = "movewindow l";
    move-column-right = "movewindow r";
    move-window-down-or-to-workspace-down = "movewindow d";
    move-window-up-or-to-workspace-up = "movewindow u";
    focus-workspace-down = "workspace e-1";
    focus-workspace-up = "workspace e+1";
    focus-workspace = "workspace";
    move-column-to-workspace = "movetoworkspace";
    move-workspace-down = "movecurrentworkspacetodmon l";
    move-workspace-up = "movecurrentworkspacetodmon r";
    toggle-overview = "overview:toggle";
    maximize-column = "fullscreen";
    fullscreen-window = "fullscreen 1";
    center-column = "centerwindow";
    quit = "exit";
    screenshot = "exec grimblast copy area";
    screenshot-screen = "exec grimblast copy output";
    screenshot-window = "exec grimblast copy window";
    toggle-window-floating = "togglefloating";
    switch-preset-column-width = "togglesplit";
  };

  toHyprlandStr =
    s:
    let
      actionName = head (attrNames s.action);
      actionValue = head (attrValues s.action);
      dispatcher = niriToHyprDispatcher.${actionName} or null;
    in
    if dispatcher == null then
      null
    else
      let
        modStr = if s.mod == [ ] then "" else "${toHyprMod s.mod}, ";
        # -- build params
        params =
          if isList actionValue then
            if actionName == "spawn" then lib.concatStringsSep " " actionValue else ""
          else if isInt actionValue then
            toString actionValue
          else
            actionValue;
        dispStr = if params == "" then dispatcher else "${dispatcher} ${params}";
      in
      "${modStr}${s.key}, ${dispStr}";

  workspaceActions = [
    "focus-workspace"
    "move-column-to-workspace"
  ];

  isWorkspaceAction = s: builtins.elem (head (attrNames s.action)) workspaceActions;

  toHyprlandBindsList =
    { myconfig }:
    lib.filter (x: x != null) (
      map toHyprlandStr (filter (s: s.enable && !isWorkspaceAction s) (myconfig.user.shortcuts or [ ]))
    );

in
{
  inherit toNiriBinds toHyprlandBindsList;
}
