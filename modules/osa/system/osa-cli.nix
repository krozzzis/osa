{
  delib,
  pkgs,
  ...
}:
let
  package = import ../../../packages/osa { inherit pkgs; };
in
delib.module {
  name = "osa.system.osa-cli";

  options = { ... }: {
    osa.system.osa-cli.enable = delib.boolOption true;
    osa.system.osa-cli.pkg = delib.packageOption package;
  };

  nixos.ifEnabled = { cfg, ... }: {
    environment.systemPackages = [ cfg.pkg ];
  };
}
