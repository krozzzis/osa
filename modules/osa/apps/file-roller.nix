{ delib, lib, ... }:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.apps.fileRoller" (
      { pkgs }:
      delib.module {
        name = "osa.apps.fileRoller";

        options.osa.apps.fileRoller = {
          enable = delib.boolOption false;
          desktop = delib.strOption "org.gnome.FileRoller.desktop";
          pkg = delib.packageOption pkgs.file-roller;
        };

        home.ifEnabled =
          { cfg, ... }:
          let
            associations = lib.genAttrs [
              "application/zip"
              "application/x-7z-compressed"
              "application/vnd.rar"
              "application/x-rar"
              "application/x-tar"
              "application/x-compressed-tar"
              "application/x-bzip-compressed-tar"
              "application/x-xz-compressed-tar"
              "application/x-zstd-compressed-tar"
              "application/gzip"
              "application/x-bzip2"
              "application/x-xz"
              "application/zstd"
            ] (_: [ cfg.desktop ]);
          in
          {
            home.packages = [ cfg.pkg ];
            xdg.mimeApps = {
              enable = true;
              defaultApplications = associations;
              associations.added = associations;
            };
          };
      }
    ))
  ];
}
