{
  delib,
  lib,
  ...
}:
{
  imports = [
    ((import ../../../../lib/package-module.nix) "osa.de.hyprland" (
      { pkgs }:
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
            package = pkgs.hyprland;
            portalPackage = pkgs.xdg-desktop-portal-hyprland;
            withUWSM = true;
            xwayland.enable = true;
          };
        };
      }
    ))
  ];
}
