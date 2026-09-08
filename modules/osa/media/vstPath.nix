{
  delib,
  lib,
  ...
}:
delib.module {
  name = "osa.media.vstPath";

  options = { ... }: {
    osa.media.vstPath.enable = delib.boolOption false;

    osa.media.vstPath.plugins =
      delib.description (delib.listOfOption lib.types.package [ ])
        "Plugin packs (LV2/VST2/VST3/CLAP/LADSPA/DSSI) to install and expose to every plugin host via *_PATH env vars";
  };

  nixos.ifEnabled =
    { myconfig, cfg, ... }:
    let
      inherit (myconfig.user.constants) username;

      # Plugin hosts on NixOS find nothing by default: the paths they are
      # compiled with (/usr/lib/lv2, ...) do not exist. Every host reads a
      # `<FORMAT>_PATH` variable instead, so build one per format out of the
      # user's own directories plus every package in `plugins`.
      pluginPath =
        dir:
        lib.concatStringsSep ":" (
          [
            "/home/${username}/.${dir}"
            "/home/${username}/.nix-profile/lib/${dir}"
            "/run/current-system/sw/lib/${dir}"
          ]
          ++ map (pkg: "${pkg}/lib/${dir}") cfg.plugins
        );
    in
    {
      environment.systemPackages = cfg.plugins;

      environment.sessionVariables = {
        LV2_PATH = pluginPath "lv2";
        LADSPA_PATH = pluginPath "ladspa";
        DSSI_PATH = pluginPath "dssi";
        CLAP_PATH = pluginPath "clap";
        VST_PATH = pluginPath "vst";
        LXVST_PATH = pluginPath "vst";
        VST3_PATH = pluginPath "vst3";
      };
    };
}
