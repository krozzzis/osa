{
  delib,
  lib,
  ...
}:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.media.obs" (
      { pkgs }:
      delib.module {
        name = "osa.media.obs";

        options = { myconfig, ... }: {
          osa.media.obs.enable = delib.boolOption myconfig.user.gui.enable;
          osa.media.obs.pkg = delib.packageOption pkgs.obs-studio;
          osa.media.obs.plugins = lib.mkOption {
            type = with lib.types; listOf package;
            default = with pkgs.obs-studio-plugins; [
              obs-pipewire-audio-capture
              obs-vaapi
              obs-vkcapture
            ];
            description = "OBS Studio plugins to install.";
          };
        };

        nixos.ifEnabled = { cfg, ... }: {
          programs.obs-studio = {
            enable = true;
            enableVirtualCamera = true;
            package = cfg.pkg;
            plugins = cfg.plugins;
          };
        };
      }
    ))
  ];
}
