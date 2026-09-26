{ delib, ... }:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.shell.ripgrep" (
      { pkgs }:
      delib.module {
        name = "osa.shell.ripgrep";

        options = { myconfig, ... }: {
          osa.shell.ripgrep.enable = delib.boolOption myconfig.user.shell.enable;
        };

        home.ifEnabled = {
          programs.ripgrep = {
            package = pkgs.ripgrep;
            enable = true;
          };
        };
      }
    ))
  ];
}
