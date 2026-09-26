{
  delib,
  inputs,
  ...
}:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.shell.rip" (
      { pkgs }:
      let
        package =
          ((import "${inputs.rip}/flake.nix").outputs {
            self = inputs.rip;
            nixpkgs = {
              inherit (pkgs) lib;
              outPath = pkgs.path;
            };
            inherit (inputs.rip.inputs) flake-utils;
          }).packages.${pkgs.stdenv.hostPlatform.system}.default;
      in
      delib.module {
        name = "osa.shell.rip";

        options = { myconfig, ... }: {
          osa.shell.rip.enable = delib.boolOption myconfig.user.shell.enable;
          osa.shell.rip.pkg = delib.packageOption package;
        };

        home.ifEnabled = { cfg, ... }: {
          home.packages = [ cfg.pkg ];
        };
      }
    ))
  ];
}
