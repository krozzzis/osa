{ delib, ... }:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.fileManager.udiskie" (
      { pkgs }:
      delib.module {
        name = "osa.fileManager.udiskie";

        options = {
          osa.fileManager.udiskie.enable = delib.boolOption false;
          osa.fileManager.udiskie.pkg = delib.packageOption pkgs.udiskie;
        };

        nixos.ifEnabled.services.udisks2.enable = true;

        home.ifEnabled = { cfg, ... }: {
          services.udiskie = {
            enable = true;
            package = cfg.pkg;
            automount = true;
            notify = true;
            tray = "never";
            settings.notifications = {
              device_added = 5;
              device_mounted = false;
              device_unmounted = false;
              device_removed = 5;
              device_unlocked = false;
              device_locked = false;
            };
          };
        };
      }
    ))
  ];
}
