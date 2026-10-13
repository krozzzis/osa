{
  delib,
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
          osa.media.cloudmus.pkg = delib.packageOption (
            pkgs.callPackage ../../../packages/cloudmus { backends = backendPython; }
          );
        };

        home.ifEnabled = { cfg, ... }: {
          home.packages = [
            cfg.pkg
          ];

          # The front reads backend manifests only from this directory, so
          # link in the ones the package generated with store paths.
          xdg.configFile."cloudmus/backends.d".source = "${cfg.pkg}/share/cloudmus/backends.d";
        };
      }
    ))
  ];
}
