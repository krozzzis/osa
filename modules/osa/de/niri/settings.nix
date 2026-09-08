{ delib, ... }:
delib.module {
  name = "osa.de.niri";

  home.ifEnabled = {
    programs.niri.settings = {
      # -- Spawn at startup
      spawn-at-startup = [
        { argv = [ "xwayland-satellite" ]; }
        {
          # clear clipboard at niri start — use sh -c to expand $XDG_CACHE_HOME, avoid WAYLAND_DISPLAY terminal flash
          argv = [
            "sh"
            "-c"
            "rm -f \"$XDG_CACHE_HOME/cliphist/db\" 2>/dev/null || true"
          ];
        }
      ];

      # -- environment variables within niri
      environment = {
        DISPLAY = ":0";
        QT_QPA_PLATFORM = "wayland";
      };

      hotkey-overlay = {
        skip-at-startup = true;
        hide-not-bound = true;
      };

      # -- Misc settings
      prefer-no-csd = true; # omit client side window decorations
      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
      animations.enable = true;

      # -- Named workspaces
      workspaces."1" = { };
      workspaces."2" = { };
      workspaces."3" = { };
      workspaces."4" = { };
      workspaces."5" = { };
      workspaces."6" = { };
      workspaces."7" = { };
      workspaces."8" = { };
      workspaces."9" = { };
      workspaces."10" = { };
    };
  };
}
