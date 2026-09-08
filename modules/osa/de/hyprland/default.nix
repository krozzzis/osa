{
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.de.hyprland";

  options = { ... }: {
    osa.de.hyprland.enable = delib.boolOption false;
    osa.de.hyprland.launcher.default = lib.mkOption {
      type = lib.types.attrs;
      default = {
        pkg = pkgs.walker;
      };
    };
  };

  nixos.ifEnabled = {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };
  };
}
