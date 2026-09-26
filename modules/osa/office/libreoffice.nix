{
  delib,
  pkgs,
  lib,
  ...
}:
delib.module {
  name = "osa.office.libreoffice";

  options = { myconfig, ... }: {
    osa.office.libreoffice.pkg = delib.packageOption pkgs.libreoffice-qt-stable;
    osa.office.libreoffice.enable = delib.boolOption myconfig.user.gui.enable;
  };

  home.ifEnabled = { cfg, ... }: {
    xdg.mimeApps = {
      enable = true;
      defaultApplications = lib.mapAttrs (_: lib.mkDefault) (
        lib.genAttrs [
          "application/vnd.oasis.opendocument.text"
          "application/vnd.oasis.opendocument.text-template"
          "application/msword"
          "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
          "application/vnd.openxmlformats-officedocument.wordprocessingml.template"
          "application/rtf"
          "text/rtf"
        ] (_: [ "writer.desktop" ])
        // lib.genAttrs [
          "application/vnd.oasis.opendocument.spreadsheet"
          "application/vnd.oasis.opendocument.spreadsheet-template"
          "application/vnd.ms-excel"
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
          "application/vnd.openxmlformats-officedocument.spreadsheetml.template"
          "text/csv"
          "text/tab-separated-values"
        ] (_: [ "calc.desktop" ])
        // lib.genAttrs [
          "application/vnd.oasis.opendocument.presentation"
          "application/vnd.oasis.opendocument.presentation-template"
          "application/vnd.ms-powerpoint"
          "application/vnd.openxmlformats-officedocument.presentationml.presentation"
          "application/vnd.openxmlformats-officedocument.presentationml.slideshow"
        ] (_: [ "impress.desktop" ])
        // {
          "application/vnd.oasis.opendocument.graphics" = [ "draw.desktop" ];
          "application/vnd.oasis.opendocument.formula" = [ "math.desktop" ];
          "application/vnd.oasis.opendocument.database" = [ "base.desktop" ];
        }
      );
    };
    home.packages = with pkgs; [
      cfg.pkg
      hyphenDicts.ru-ru
      hyphenDicts.en-us
    ];
  };
}
