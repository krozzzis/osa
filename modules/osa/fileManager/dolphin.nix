{ delib, lib, ... }:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.fileManager.dolphin" (
      { pkgs }:
      let
        # Adwaita's palette polish otherwise discards the KDE/Matugen colors.
        style = pkgs.adwaita-qt6.overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            substituteInPlace src/style/adwaitastyle.cpp \
              --replace-fail 'palette = Colors::palette(_variant);' 'ParentStyleClass::polish(palette);'
          '';
        });
      in
      delib.module {
        name = "osa.fileManager.dolphin";
        options.osa.fileManager.dolphin = {
          enable = delib.boolOption false;
          desktop = delib.strOption "org.kde.dolphin.desktop";
          pkg = delib.packageOption (
            pkgs.kdePackages.dolphin.overrideAttrs (old: {
              qtWrapperArgs = (old.qtWrapperArgs or [ ]) ++ [
                "--prefix"
                "QT_PLUGIN_PATH"
                ":"
                "${style}/${pkgs.qt6.qtbase.qtPluginPrefix}"
                "--set"
                "QT_STYLE_OVERRIDE"
                "adwaita"
              ];
            })
          );
        };
        nixos.ifEnabled.services.udisks2.enable = true;
        home.ifEnabled = { cfg, myconfig, ... }: {
          home.packages = [
            cfg.pkg
            style
          ];
          xdg.configFile."kdeglobals".text = lib.mkIf myconfig.osa.de.dms.enable (
            lib.mkAfter ''
              [General]
              ColorScheme=DankMatugen
            ''
          );
        };
      }
    ))
  ];
}
