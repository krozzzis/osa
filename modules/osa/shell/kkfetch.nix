{
  delib,
  inputs,
  ...
}:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.shell.kkfetch" (
      { pkgs }:
      let
        package = inputs.kkfetch.packages.${pkgs.stdenv.hostPlatform.system}.default;
      in
      delib.module {
        name = "osa.shell.kkfetch";

        options = { myconfig, ... }: {
          osa.shell.kkfetch.enable = delib.boolOption myconfig.user.shell.enable;
          osa.shell.kkfetch.pkg = delib.packageOption package;
        };

        home.ifEnabled = { cfg, ... }: {
          home.packages = [ cfg.pkg ];
        };
      }
    ))
  ];
}
