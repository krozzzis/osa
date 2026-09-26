{
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.apps.wine";

  options = {
    osa.apps.wine = {
      enable = delib.boolOption false;
      pkg = delib.packageOption pkgs.wineWow64Packages.stable;
      desktop = delib.strOption "osa-wine.desktop";
      defaultApplication = delib.description (delib.boolOption true) "Open Windows executables, installers and shortcuts with Wine.";
      profiles = lib.mkOption {
        default = { };
        description = "Named Wine launchers with separate prefixes relative to the home directory.";
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              prefix = lib.mkOption {
                type = lib.types.strMatching "[^/].*";
                description = "Wine prefix path relative to the home directory.";
              };
              locale = lib.mkOption {
                type = lib.types.nullOr lib.types.nonEmptyStr;
                default = null;
                example = "ru_RU.UTF-8";
                description = "Optional UTF-8 locale; generated automatically on NixOS.";
              };
            };
          }
        );
      };
    };
  };

  nixos.ifEnabled = { cfg, ... }: {
    i18n.extraLocales = lib.unique (
      lib.mapAttrsToList (_: profile: "${profile.locale}/UTF-8") (
        lib.filterAttrs (_: profile: profile.locale != null) cfg.profiles
      )
    );
  };

  home.ifEnabled =
    { cfg, ... }:
    let
      mimeTypes = [
        "application/x-ms-dos-executable"
        "application/vnd.microsoft.portable-executable"
        "application/x-msdownload"
        "application/x-msi"
        "application/x-ms-shortcut"
        "application/x-bat"
        "application/x-mswinurl"
      ];
      associations = lib.genAttrs mimeTypes (_: [ cfg.desktop ]);
    in
    {
      home.packages = [
        cfg.pkg
      ]
      ++ lib.mapAttrsToList (
        name: profile:
        pkgs.writeShellScriptBin name ''
          ${lib.optionalString (profile.locale != null) ''
            export LANG=${lib.escapeShellArg profile.locale}
            export LC_ALL=${lib.escapeShellArg profile.locale}
          ''}
          export WINEPREFIX="$HOME"/${lib.escapeShellArg profile.prefix}
          exec ${lib.getExe cfg.pkg} "$@"
        ''
      ) cfg.profiles;
      xdg.desktopEntries.${lib.removeSuffix ".desktop" cfg.desktop} = {
        name = "Wine Windows Program Loader";
        exec = "${lib.getExe cfg.pkg} start /unix %f";
        icon = "wine";
        noDisplay = true;
        terminal = false;
        categories = [
          "System"
          "Emulator"
        ];
        mimeType = mimeTypes;
      };
      xdg.mimeApps = lib.mkIf cfg.defaultApplication {
        enable = true;
        defaultApplications = associations;
        associations.added = associations;
      };
    };
}
