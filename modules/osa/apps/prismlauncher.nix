{
  delib,
  ...
}:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.apps.prismlauncher" (
      { pkgs }:
      delib.module {
        name = "osa.apps.prismlauncher";

        options = { myconfig, ... }: {
          osa.apps.prismlauncher.enable = delib.boolOption myconfig.user.gui.enable;
        };

        home.ifEnabled = {
          home.packages = with pkgs; [
            prismlauncher
          ];
        };
      }
    ))
  ];
}
