{ delib, ... }:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.terminal.wezterm" (
      { pkgs }:
      delib.module {
        name = "osa.terminal.wezterm";

        options = { cfg, myconfig, ... }: {
          osa.terminal.wezterm.enable = delib.boolOption myconfig.user.gui.enable;
          osa.terminal.wezterm.desktop = delib.strOption "org.wezfurlong.wezterm.desktop";
          osa.terminal.wezterm.notifications.autoExpire = delib.description (delib.boolOption true)
            "Use normal urgency and the notification server's default timeout for WezTerm notifications.";
          osa.terminal.wezterm.pkg = delib.packageOption (
            if cfg.notifications.autoExpire then
              pkgs.wezterm.overrideAttrs (old: {
                # WezTerm marks every DBus toast as Critical and uses an infinite
                # timeout when none was requested. Let DMS expire routine notices.
                postPatch = (old.postPatch or "") + ''
                  substituteInPlace wezterm-toast-notification/src/dbus.rs \
                    --replace-fail 'hints.insert("urgency", Value::U8(2 /* Critical */));' \
                      'hints.insert("urgency", Value::U8(1 /* Normal */));'
                  substituteInPlace wezterm-toast-notification/src/dbus.rs \
                    --replace-fail 'notif.timeout.map(|d| d.as_millis() as _).unwrap_or(0),' \
                      'notif.timeout.map(|d| d.as_millis() as _).unwrap_or(-1),'
                '';
              })
            else
              pkgs.wezterm
          );
        };

        # Look & feel is personal taste -- see modules/dotfiles/wezterm.nix in the
        # osa-user flake, which extends this same module by name.
        home.ifEnabled = { cfg, myconfig, ... }: {
          programs.wezterm = {
            package = cfg.pkg;
            enable = true;
            settings = {
              # Share the global opacity with DMS and other supported UI components.
              window_background_opacity = myconfig.osa.ui.transparency;
              text_background_opacity = 1.0;
              wayland_window_background_blur = true;
              colors = {
                background = "#0a0a0a";
                foreground = "#e0e0e0";
                cursor_bg = "#e0e0e0";
                cursor_fg = "#0a0a0a";
              };
            };
          };
        };
      }
    ))
  ];
}
