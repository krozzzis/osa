{
  delib,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  package = inputs.koala-clash.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
delib.module {
  name = "osa.apps.koalaClash";

  options = { myconfig, ... }: {
    osa.apps.koalaClash = {
      enable = delib.boolOption myconfig.user.gui.enable;
      pkg = delib.packageOption package;
      tunMode = delib.description (delib.boolOption true) "Enable TUN mode for VPN";
    };
  };

  nixos.ifEnabled =
    { cfg, ... }:
    {
      environment.systemPackages = [ cfg.pkg ];

      security.wrappers = lib.mkIf cfg.tunMode {
        koala-clash = {
          owner = "root";
          group = "root";
          source = "${cfg.pkg}/bin/koala-clash";
          capabilities = "cap_net_admin+ep";
        };
      };
    };
}
