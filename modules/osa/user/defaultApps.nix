{
  delib,
  lib,
  pkgs,
  ...
}:
let
  osaTypes = import ../../../lib/types.nix { inherit lib; };
in
delib.module {
  name = "user.defaultApps";

  options = { myconfig, ... }: {
    user.terminal.default = lib.mkOption {
      type = osaTypes.app;
      default = {
        pkg = myconfig.osa.terminal.wezterm.pkg;
        desktop = "org.wezfurlong.wezterm.desktop";
      };
      description = "Default terminal application.";
    };
    user.browser.default = lib.mkOption {
      type = osaTypes.app;
      default =
        if myconfig.osa.browser.zenBrowser.enable or false then
          myconfig.osa.browser.zenBrowser
        else if myconfig.osa.browser.firefox.enable or false then
          { pkg = myconfig.osa.browser.firefox.pkg; }
        else
          { pkg = pkgs.firefox; };
      description = "Default web browser.";
    };
    user.fileManager.default = lib.mkOption {
      type = osaTypes.app;
      default = {
        pkg = myconfig.osa.fileManager.nautilus.pkg;
        desktop = myconfig.osa.fileManager.nautilus.desktop;
      };
      description = "Default file manager.";
    };
    user.musicPlayer.default = lib.mkOption {
      type = osaTypes.app;
      default = {
        pkg = myconfig.osa.media.vlc.pkg;
      };
      description = "Default music player.";
    };
    user.videoPlayer.default = lib.mkOption {
      type = osaTypes.app;
      default = {
        pkg = myconfig.osa.media.vlc.pkg;
      };
      description = "Default video player.";
    };
    user.imageViewer.default = lib.mkOption {
      type = osaTypes.app;
      default = {
        pkg = myconfig.osa.apps.loupe.pkg;
        desktop = myconfig.osa.apps.loupe.desktop;
      };
      description = "Default image viewer.";
    };
    user.pdfViewer.default = lib.mkOption {
      type = osaTypes.app;
      default = {
        pkg = myconfig.osa.apps.papers.pkg;
        desktop = "org.gnome.Papers.desktop";
      };
      description = "Default PDF viewer.";
    };

    user.defaultApps.mimeTypes = {
      editor = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "text/plain"
          "text/markdown"
          "text/x-log"
          "application/json"
          "application/toml"
          "application/x-yaml"
          "text/yaml"
        ];
        description = "MIME types opened by the default GUI editor.";
      };
      browser = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "text/html"
          "application/xhtml+xml"
          "x-scheme-handler/http"
          "x-scheme-handler/https"
        ];
        description = "MIME types and URI schemes opened by the default browser.";
      };
      fileManager = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "inode/directory" ];
        description = "MIME types opened by the default file manager.";
      };
      musicPlayer = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "audio/aac"
          "audio/flac"
          "audio/mp4"
          "audio/mpeg"
          "audio/ogg"
          "audio/opus"
          "audio/vnd.wave"
          "audio/wav"
          "audio/webm"
          "audio/x-aiff"
          "audio/x-flac"
          "audio/x-m4a"
          "audio/x-matroska"
          "audio/x-mpegurl"
          "audio/x-ms-wma"
          "audio/x-wav"
          "application/ogg"
          "application/x-ogg"
          "application/xspf+xml"
          "audio/x-scpls"
          "application/vnd.apple.mpegurl"
          "application/x-mpegurl"
        ];
        description = "MIME types opened by the default music player.";
      };
      videoPlayer = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "video/mp2t"
          "video/mp4"
          "video/mpeg"
          "video/ogg"
          "video/quicktime"
          "video/webm"
          "video/x-flv"
          "video/x-matroska"
          "video/x-ms-asf"
          "video/x-ms-wmv"
          "video/x-msvideo"
          "video/3gpp"
          "video/3gpp2"
        ];
        description = "MIME types opened by the default video player.";
      };
      imageViewer = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "image/avif"
          "image/bmp"
          "image/gif"
          "image/heic"
          "image/heif"
          "image/jpeg"
          "image/jxl"
          "image/png"
          "image/svg+xml"
          "image/svg+xml-compressed"
          "image/tiff"
          "image/vnd.microsoft.icon"
          "image/webp"
          "image/x-icon"
          "image/x-portable-anymap"
          "image/x-portable-bitmap"
          "image/x-portable-graymap"
          "image/x-portable-pixmap"
          "image/x-qoi"
          "image/x-tga"
        ];
        description = "MIME types opened by the default image viewer.";
      };
      pdfViewer = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "application/pdf" ];
        description = "MIME types opened by the default PDF viewer.";
      };
    };
  };

  nixos.always = { myconfig, ... }: {
    environment.variables.EDITOR = lib.getExe myconfig.user.editor.default.pkg;
  };

  home.always = { myconfig, ... }: {
    imports = [
      (
        { config, ... }:
        let
          user = myconfig.user;
          apps = {
            editor = user.editor.gui;
            browser = user.browser.default;
            fileManager = user.fileManager.default;
            musicPlayer = user.musicPlayer.default;
            videoPlayer = user.videoPlayer.default;
            imageViewer = user.imageViewer.default;
            pdfViewer = user.pdfViewer.default;
          };
          # Home Manager installs Zed's wrapper when extraPackages are configured.
          # Adding the underlying package again collides on bin/zeditor and loses
          # the wrapper's language-server PATH. Compare packages, not app names, so
          # custom handles and disabled Zed configurations still get installed.
          zed = config.programs.zed-editor;
          needsInstallation = app: !(zed.enable && zed.package != null && app.pkg == zed.package);
          desktopId =
            app:
            if (app.desktop or null) != null then
              app.desktop
            else
              "${app.pkg.meta.mainProgram or (lib.getName app.pkg)}.desktop";
          associations = lib.mkMerge (
            lib.mapAttrsToList (
              category: app: lib.genAttrs user.defaultApps.mimeTypes.${category} (_: [ (desktopId app) ])
            ) apps
          );
        in
        lib.mkMerge [
          { home.sessionVariables.EDITOR = lib.getExe user.editor.default.pkg; }
          (lib.mkIf user.gui.enable {
            # Handles are authoritative even when the corresponding module is disabled.
            home.packages = lib.unique (
              map (app: app.pkg) (
                builtins.filter needsInstallation (builtins.attrValues apps ++ [ user.terminal.default ])
              )
            );
            home.sessionVariables = {
              BROWSER = lib.getExe user.browser.default.pkg;
              TERMINAL = lib.getExe user.terminal.default.pkg;
            };
            xdg.mimeApps = {
              enable = true;
              defaultApplications = associations;
              associations.added = associations;
            };
          })
        ]
      )
    ];
  };
}
