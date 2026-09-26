{
  delib,
  ...
}:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.shell.usbutils" (
      { pkgs }:
      delib.module {
        name = "osa.shell.usbutils";

        options = { myconfig, ... }: {
          osa.shell.usbutils.enable = delib.boolOption myconfig.user.shell.enable;
        };

        nixos.ifEnabled = {
          environment.systemPackages = with pkgs; [
            usbutils
            openocd
          ];
        };
      }
    ))
  ];
}
