{
  delib,
  ...
}:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.shell.ghCli" (
      { pkgs }:
      delib.module {
        name = "osa.shell.ghCli";

        options = { myconfig, ... }: {
          osa.shell.ghCli.enable = delib.boolOption myconfig.user.shell.enable;
        };

        home.ifEnabled = {
          programs.gh = {
            package = pkgs.gh;
            enable = true;

            gitCredentialHelper = {
              enable = true;
            };
          };
        };
      }
    ))
  ];
}
