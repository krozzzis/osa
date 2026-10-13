{
  delib,
  ...
}:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.shell.nixFastBuild" (
      { pkgs }:
      delib.module {
        name = "osa.shell.nixFastBuild";

        options = { myconfig, ... }: {
          osa.shell.nixFastBuild.enable = delib.boolOption myconfig.user.shell.enable;
        };

        home.ifEnabled = {
          home.packages = with pkgs; [
            nix-fast-build
          ];
        };
      }
    ))
  ];
}
