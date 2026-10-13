{
  delib,
  lib,
  ...
}:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.media.cloudmus" (
      { pkgs }:
      let
        # cloudmus-qt speaks JSON-RPC to one Python process per source, so
        # the backends' interpreter is built here next to the front.
        backendPython = pkgs.python3.withPackages (ps: [
          ps.mutagen
          ps.pysocks
          ps.requests
          ps.ytmusicapi
          ps.yt-dlp
          (ps.callPackage ../../../packages/yandex-music { })
        ]);
      in
      delib.module {
        name = "osa.media.cloudmus";

        options = { myconfig, ... }: {
          osa.media.cloudmus.enable = delib.boolOption myconfig.user.gui.enable;
          osa.media.cloudmus.notifications = lib.mkOption {
            type = lib.types.enum [
              "FULL"
              "SILENT"
              "DISABLED"
            ];
            default = "SILENT";
            description = ''
              Track-change and hotkey popups: FULL is upstream behavior,
              SILENT shows them without a sound (freedesktop suppress-sound
              hint, honored by DMS), DISABLED sends none at all.
            '';
          };
          osa.media.cloudmus.pkg = delib.packageOption (
            pkgs.callPackage ../../../packages/cloudmus { backends = backendPython; }
          );
        };

        home.ifEnabled = { cfg, ... }: {
          home.packages = [
            cfg.pkg
          ];

          # The patched front reads the mode from its environment, so the
          # choice stays a Home Manager setting instead of a rebuild.
          home.sessionVariables.CLOUDMUS_NOTIFICATIONS = cfg.notifications;

          # The front reads backend manifests only from this directory, so
          # link in the ones the package generated with store paths.
          xdg.configFile."cloudmus/backends.d".source = "${cfg.pkg}/share/cloudmus/backends.d";
        };
      }
    ))
  ];
}
