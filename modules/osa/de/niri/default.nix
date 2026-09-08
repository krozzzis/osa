{
  delib,
  lib,
  inputs,
  pkgs,
  ...
}:
delib.module {
  name = "osa.de.niri";

  options = { myconfig, ... }: {
    osa.de.niri.enable = delib.boolOption myconfig.user.gui.enable;
    osa.de.niri.launcher.default = lib.mkOption {
      type = lib.types.attrs;
      default = {
        pkg = myconfig.osa.apps.walker.pkg;
      };
    };
  };

  nixos.always.imports = [ inputs.niri-pkgs.nixosModules.niri ];

  nixos.always.nixpkgs.overlays = [
    (_final: prev: {
      libdisplay-info_0_2 = prev.libdisplay-info.overrideAttrs (_old: {
        version = "0.2.0";
        src = prev.fetchFromGitLab {
          domain = "gitlab.freedesktop.org";
          owner = "emersion";
          repo = "libdisplay-info";
          tag = "0.2.0";
          hash = "sha256-6xmWBrPHghjok43eIDGeshpUEQTuwWLXNHg7CnBUt3Q=";
        };
      });
    })
    inputs.niri-pkgs.overlays.niri
  ];

  nixos.ifEnabled = {
    programs.niri.enable = true;
    # greetd starts niri-session before a Wayland socket exists. Importing a
    # fixed list then makes systemctl print "$WAYLAND_DISPLAY not set" to the
    # VT, which becomes visible during the greeter -> session handoff. Import
    # only variables that actually exist in the login environment.
    programs.niri.package = pkgs.niri-unstable.overrideAttrs (old: {
      postFixup = (old.postFixup or "") + ''
        substituteInPlace $out/bin/niri-session \
          --replace-fail \
            'systemctl --user import-environment' \
            'niri_environment=
            [ -z "''${WAYLAND_DISPLAY-}" ] || niri_environment="$niri_environment WAYLAND_DISPLAY"
            [ -z "''${DISPLAY-}" ] || niri_environment="$niri_environment DISPLAY"
            [ -z "''${XDG_SESSION_TYPE-}" ] || niri_environment="$niri_environment XDG_SESSION_TYPE"
            [ -z "''${XDG_CURRENT_DESKTOP-}" ] || niri_environment="$niri_environment XDG_CURRENT_DESKTOP"
            [ -z "''${NIRI_SOCKET-}" ] || niri_environment="$niri_environment NIRI_SOCKET"
            [ -z "$niri_environment" ] || systemctl --user import-environment $niri_environment'
      '';
    });

    # use the gnome polkit rather than the kde one installed
    # by default with the niri flake
    systemd.user.services.niri-flake-polkit = {
      enable = false;
    };

    environment.variables.NIXOS_OZONE_WL = "1";

    environment.variables.QT_QPA_PLATFORMTHEME = "kde";

    environment.sessionVariables.SSH_AUTH_SOCK = "\${XDG_RUNTIME_DIR}/keyring/ssh";

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome # нужен для ScreenCast (запись экрана в OBS и т.п.)
      ];
    };

    # Важно: GTK-портал не реализует ScreenCast, поэтому запись экрана
    # (OBS, screen sharing) явно направляется на gnome-портал,
    # а выбор файлов остаётся на GTK-портале.
    xdg.portal.config = {
      niri = {
        default = [ "gtk" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
      };
      common.default = [ "gtk" ];
    };

    environment.systemPackages = with pkgs; [
      xwayland-satellite
      wayland-utils
      libnotify
      brightnessctl
      networkmanagerapplet
      pamixer
      pulsemixer
      pavucontrol
      wtype
    ];

  };

}
