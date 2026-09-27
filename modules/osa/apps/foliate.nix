{ delib, lib, ... }:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.apps.foliate" (
      { pkgs }:
      delib.module {
        name = "osa.apps.foliate";
        options.osa.apps.foliate = {
          enable = delib.boolOption false;
          desktop = delib.strOption "com.github.johnfactotum.Foliate.desktop";
          pkg = delib.packageOption pkgs.foliate;
        };
        home.ifEnabled =
          { cfg, ... }:
          let
            # Formats advertised by Foliate's desktop file; PDF keeps its viewer.
            associations = lib.genAttrs [
              "application/epub+zip"
              "application/x-mobipocket-ebook"
              "application/vnd.amazon.mobi8-ebook"
              "application/x-fictionbook+xml"
              "application/x-zip-compressed-fb2"
              "application/vnd.comicbook+zip"
              "x-scheme-handler/opds"
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
