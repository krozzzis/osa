{
  delib,
  lib,
  ...
}:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.apps.android" (
      { pkgs }:
      delib.module {
        name = "osa.apps.android";

        options = { myconfig, ... }: {
          osa.apps.android = {
            enable = delib.boolOption myconfig.user.gui.enable;
            tools = delib.description (delib.boolOption true) "Android tools (adb, fastboot)";
            screencast = delib.description (delib.boolOption true) "Android screen mirroring (scrcpy)";
          };
        };

        nixos.ifEnabled =
          { cfg, ... }:
          let
            packages =
              with pkgs;
              ((lib.optionals cfg.tools [ android-tools ]) ++ (lib.optionals cfg.screencast [ scrcpy ]));
          in
          {
            environment.systemPackages = packages;
          };

        home.ifEnabled =
          { cfg, ... }:
          lib.mkIf cfg.screencast {
            xdg.desktopEntries.scrcpy = {
              name = "Scrcpy";
              comment = "Android screen mirroring";
              exec = "scrcpy --always-on-top";
              icon = "scrcpy";
              terminal = false;
              categories = [ "Utility" ];
            };
          };
      }
    ))
  ];
}
