{
  delib,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  tomlFormat = pkgs.formats.toml { };
in
delib.module {
  name = "osa.de.driftwm";

  options = { myconfig, ... }: {
    osa.de.driftwm = {
      enable = delib.boolOption false;
      pkg = delib.packageOption inputs.driftwm.packages.${pkgs.stdenv.hostPlatform.system}.default;
      launcher.default = lib.mkOption {
        type = lib.types.attrs;
        default = myconfig.osa.apps.walker;
        description = "Launcher handle exported to DriftWM through LAUNCHER.";
      };
      settings = lib.mkOption {
        inherit (tomlFormat) type;
        default = { };
        description = "Declarative DriftWM configuration written to driftwm/config.toml.";
      };
    };
  };

  nixos.always.imports = [ inputs.driftwm.nixosModules.default ];

  nixos.ifEnabled =
    { cfg, ... }:
    {
      programs.driftwm = {
        enable = true;
        package = cfg.pkg;
      };

      environment = {
        variables = {
          LAUNCHER = lib.getExe cfg.launcher.default.pkg;
          NIXOS_OZONE_WL = "1";
        };
        systemPackages = with pkgs; [
          brightnessctl
          grim
          libnotify
          pamixer
          playerctl
          slurp
          wayland-utils
          wl-clipboard
          wtype
        ];
      };
    };

  home.ifEnabled =
    { cfg, ... }:
    {
      xdg.configFile."driftwm/config.toml".source =
        tomlFormat.generate "driftwm-config.toml" cfg.settings;
    };
}
