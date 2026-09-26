{
  delib,
  ...
}:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.apps.throne" (
      { pkgs }:
      delib.module {
        name = "osa.apps.throne";

        options = { myconfig, ... }: {
          osa.apps.throne = {
            enable = delib.boolOption myconfig.user.gui.enable;
            tunMode = delib.description (delib.boolOption true) "Enable TUN mode for VPN";
          };
        };

        nixos.ifEnabled = { cfg, ... }: {
          programs.throne = {
            package = pkgs.throne;
            enable = true;
            tunMode.enable = cfg.tunMode;
          };
        };
      }
    ))
  ];
}
