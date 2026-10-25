{ delib, ... }:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.apps.stm32cubemx" (
      { pkgs }:
      delib.module {
        name = "osa.apps.stm32cubemx";

        options = {
          osa.apps.stm32cubemx.enable = delib.boolOption false;
          osa.apps.stm32cubemx.pkg = delib.packageOption pkgs.stm32cubemx;
        };

        home.ifEnabled = { cfg, ... }: {
          home.packages = [ cfg.pkg ];
        };
      }
    ))
  ];
}
