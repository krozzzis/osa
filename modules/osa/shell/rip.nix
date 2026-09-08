{
  delib,
  inputs,
  pkgs,
  ...
}:
let
  package = inputs.rip.packages.${pkgs.stdenv.hostPlatform.system}.default;
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
