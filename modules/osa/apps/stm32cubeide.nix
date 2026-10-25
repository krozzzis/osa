{ delib, ... }:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.apps.stm32cubeide" (
      { pkgs }:
      delib.module {
        name = "osa.apps.stm32cubeide";

        options = {
          osa.apps.stm32cubeide.enable = delib.boolOption false;
          osa.apps.stm32cubeide.pkg = delib.packageOption (
            import ../../../packages/stm32cubeide { inherit pkgs; }
          );
        };

        home.ifEnabled = { cfg, ... }: {
          home.packages = [ cfg.pkg ];
        };

        nixos.ifEnabled = { cfg, myconfig, ... }: {
          services.udev.packages = [ cfg.pkg ];
          users.users.${myconfig.user.constants.username}.extraGroups = [ "dialout" ];
        };
      }
    ))
  ];
}
