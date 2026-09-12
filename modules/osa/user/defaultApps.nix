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
      };
      description = "Default terminal application.";
    };
    user.browser.default = lib.mkOption {
      type = osaTypes.app;
      default =
        if myconfig.osa.browser.zenBrowser.enable or false then
          { pkg = myconfig.osa.browser.zenBrowser.pkg; }
        else if myconfig.osa.browser.firefox.enable or false then
          { pkg = myconfig.osa.browser.firefox.pkg; }
        else
          { pkg = pkgs.firefox; };
      description = "Default web browser.";
    };
    user.fileManager.default = lib.mkOption {
      type = osaTypes.app;
      default = {
        pkg = pkgs.nautilus;
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
        pkg = myconfig.osa.apps.swayimg.pkg;
      };
      description = "Default image viewer.";
    };
    user.pdfViewer.default = lib.mkOption {
      type = osaTypes.app;
      default = {
        pkg = myconfig.osa.apps.cosmic.reader.pkg;
      };
      description = "Default PDF viewer.";
    };

    user.defaultApps.mimeTypes = {
      editor = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "text/plain" ];
        description = "MIME types opened by the default GUI editor.";
      };
      browser = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
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
        default = [ "audio/*" ];
        description = "MIME types opened by the default music player.";
      };
      videoPlayer = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "video/*" ];
        description = "MIME types opened by the default video player.";
      };
      imageViewer = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "image/*" ];
        description = "MIME types opened by the default image viewer.";
      };
      pdfViewer = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "application/pdf" ];
        description = "MIME types opened by the default PDF viewer.";
      };
    };
  };

  nixos.always =
    { myconfig, ... }:
    let
      bin = pkg: pkg.meta.mainProgram or (lib.getName pkg);
      desktopId = app: app.desktop or "${bin app.pkg}.desktop";
      mimeAssociations = app: mimeTypes: lib.genAttrs mimeTypes (_: desktopId app);
    in
    {
      environment.variables = {
        EDITOR = bin myconfig.user.editor.default.pkg;
        BROWSER = bin myconfig.user.browser.default.pkg;
        TERMINAL = bin myconfig.user.terminal.default.pkg;
      };

      xdg.mime.defaultApplications = lib.mkMerge [
        (mimeAssociations myconfig.user.editor.gui myconfig.user.defaultApps.mimeTypes.editor)
        (mimeAssociations myconfig.user.browser.default myconfig.user.defaultApps.mimeTypes.browser)
        (mimeAssociations myconfig.user.fileManager.default myconfig.user.defaultApps.mimeTypes.fileManager)
        (mimeAssociations myconfig.user.musicPlayer.default myconfig.user.defaultApps.mimeTypes.musicPlayer)
        (mimeAssociations myconfig.user.videoPlayer.default myconfig.user.defaultApps.mimeTypes.videoPlayer)
        (mimeAssociations myconfig.user.imageViewer.default myconfig.user.defaultApps.mimeTypes.imageViewer)
        (mimeAssociations myconfig.user.pdfViewer.default myconfig.user.defaultApps.mimeTypes.pdfViewer)
      ];
    };

  home.always =
    { myconfig, ... }:
    let
      bin = pkg: pkg.meta.mainProgram or (lib.getName pkg);
    in
    {
      home.sessionVariables = {
        EDITOR = bin myconfig.user.editor.default.pkg;
      };
    };
}
