{ delib, ... }:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.shell.htop" (
      { pkgs }:
      delib.module {
        name = "osa.shell.htop";

        options = { myconfig, ... }: {
          osa.shell.htop.enable = delib.boolOption myconfig.user.shell.enable;
        };

        home.ifEnabled = {
          programs.htop = {
            package = pkgs.htop;
            enable = true;
          };
        };
      }
    ))
  ];
}
