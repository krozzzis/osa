{ delib, lib, ... }:
delib.module {
  name = "osa.de.niri";

  home.ifEnabled = { myconfig, ... }: {
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

      # Niri keeps named workspaces alive. DMS filters its additional dynamic
      # empty workspace using the same global list.
      workspaces = lib.listToAttrs (
        lib.imap0 (index: workspace: {
          name = lib.fixedWidthNumber 2 index;
          value.name = workspace;
        }) myconfig.user.ui.workspaces
      );
    };
  };
}
