{
  delib,
  ...
}:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.media.audacity" (
      { pkgs }:
      delib.module {
        name = "osa.media.audacity";

        options = { myconfig, ... }: {
          osa.media.audacity.enable = delib.boolOption myconfig.user.gui.enable;
        };

        home.ifEnabled = {
          home.packages = with pkgs; [
            audacity
          ];
        };
      }
    ))
  ];
}
