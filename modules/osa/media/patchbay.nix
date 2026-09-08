{
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.media.patchbay";

  options = { ... }: {
    osa.media.patchbay.enable = delib.boolOption false;

    osa.media.patchbay.plugins = delib.description (delib.listOfOption lib.types.package (
      with pkgs;
      [
        lsp-plugins
        calf
        x42-plugins
        zam-plugins
      ]
    )) "Plugin packs installed and put on VST_PATH/LV2_PATH/etc. via osa.media.vstPath";

    osa.media.patchbay.carla.enable =
      delib.description (delib.boolOption true) "Carla — plugin host with its own patchbay, hosts VST2/VST3/LV2/CLAP";

    osa.media.patchbay.easyeffects.enable =
      delib.description (delib.boolOption true) "EasyEffects — GUI effect chains for the default sink/source";
    osa.media.patchbay.easyeffects.autostart =
      delib.description (delib.boolOption true) "Run EasyEffects in background so its chains apply without the window open";

    osa.media.patchbay.qpwgraph.autostart =
      delib.description (delib.boolOption true) "Start qpwgraph minimized to tray and re-apply the saved patchbay on login";

    osa.media.patchbay.yabridge.enable =
      delib.description (delib.boolOption false) "Bridge for Windows VST2/VST3 plugins (pulls in wine)";

    osa.media.patchbay.virtualSinks =
      delib.description
        (delib.attrsOfOption lib.types.str {
          "fx-1" = "FX 1";
          "fx-2" = "FX 2";
        })
        "Virtual sinks (node.name -> description) that individual apps can be moved onto for per-app processing";

    osa.media.patchbay.virtualMic = delib.description (delib.strOption "Mic FX") "Description of the virtual capture device fed by the mic effect chain; empty string disables it";
  };

  myconfig.ifEnabled = { cfg, ... }: {
    osa.system.audio.enable = true;
    osa.apps.qpwgraph.enable = true;

    osa.media.vstPath.enable = true;
    osa.media.vstPath.plugins = cfg.plugins;
  };

  nixos.ifEnabled =
    { myconfig, cfg, ... }:
    let
      # jack2's libjack talks to a jackd server that PipeWire does not provide;
      # pw-jack works around it by shadowing the library, which for a GUI app
      # launched from a menu is easier to bake into the binary itself.
      withPipewireJack =
        pkg:
        pkgs.symlinkJoin {
          name = "${lib.getName pkg}-pw";
          paths = [ pkg ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            for bin in $out/bin/*; do
              wrapProgram "$bin" --prefix LD_LIBRARY_PATH : "${pkgs.pipewire.jack}/lib"
            done
          '';
        };

      mkNullSink = args: {
        factory = "adapter";
        args = {
          "factory.name" = "support.null-audio-sink";
          "audio.position" = "FL,FR";
          "node.virtual" = true;
        }
        // args;
      };
    in
    {
      environment.systemPackages = [
        pkgs.pwvucontrol # move a single app's stream onto an FX sink
      ]
      ++ lib.optional cfg.carla.enable (withPipewireJack pkgs.carla)
      ++ lib.optional cfg.easyeffects.enable pkgs.easyeffects
      ++ lib.optionals cfg.yabridge.enable [
        pkgs.yabridge
        pkgs.yabridgectl
        pkgs.wineWowPackages.staging
      ];

      # Sinks apps can be moved onto, plus a virtual capture device: a plugin
      # host reads a sink's monitor, processes it, and writes the result back
      # into the real output (or into the virtual mic, which apps see as a
      # regular microphone).
      services.pipewire.extraConfig.pipewire."60-patchbay-devices" = {
        "context.objects" =
          lib.mapAttrsToList (
            name: description:
            mkNullSink {
              "node.name" = name;
              "node.description" = description;
              "media.class" = "Audio/Sink";
              "monitor.channel-volumes" = true;
              "monitor.passthrough" = true;
            }
          ) cfg.virtualSinks
          ++ lib.optional (cfg.virtualMic != "") (mkNullSink {
            "node.name" = "mic-fx";
            "node.description" = cfg.virtualMic;
            "media.class" = "Audio/Source/Virtual";
          });
      };

      systemd.user.services.qpwgraph = lib.mkIf cfg.qpwgraph.autostart {
        description = "qpwgraph PipeWire patchbay";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${myconfig.osa.apps.qpwgraph.pkg}/bin/qpwgraph --minimized --activated";
          Restart = "on-failure";
          RestartSec = 3;
        };
      };

      systemd.user.services.easyeffects = lib.mkIf (cfg.easyeffects.enable && cfg.easyeffects.autostart) {
        description = "EasyEffects audio effects";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.easyeffects}/bin/easyeffects --gapplication-service";
          Restart = "on-failure";
          RestartSec = 3;
        };
      };
    };
}
