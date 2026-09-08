{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.apps.rpiImager";

  options = { myconfig, ... }: {
    osa.apps.rpiImager.enable = delib.boolOption myconfig.user.gui.enable;
  };

  home.ifEnabled = {
    home.packages = with pkgs; [
      (writeShellScriptBin "rpi-imager" ''
        # Under sudo, carry the original user's X authority so X11 works
        if [ -n "''${SUDO_USER:-}" ]; then
          original_home="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
          export XAUTHORITY="''${XAUTHORITY:-$original_home/.Xauthority}"
        fi
        exec "${pkgs.rpi-imager}/bin/rpi-imager" "$@"
      '')
    ];
  };
}
