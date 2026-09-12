{ delib, pkgs, ... }:
delib.module {
  name = "osa.terminal.wezterm";

  options = { myconfig, ... }: {
    osa.terminal.wezterm.enable = delib.boolOption myconfig.user.gui.enable;
    osa.terminal.wezterm.pkg = delib.packageOption pkgs.wezterm;
  };

  # Look & feel is personal taste -- see modules/dotfiles/wezterm.nix in the
  # osa-user flake, which extends this same module by name.
  home.ifEnabled = { myconfig, ... }: {
    programs.wezterm = {
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
