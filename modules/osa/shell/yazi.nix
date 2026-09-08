{
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.shell.yazi";

  options = { myconfig, ... }: {
    osa.shell.yazi.enable = delib.boolOption myconfig.user.shell.enable;
  };

  home.ifEnabled = { myconfig, ... }: {
    home.packages = with pkgs; [
      exiftool
      mediainfo
      poppler
      chafa
      ffmpeg
      ripgrep
    ];

    programs.yazi = {
      enable = true;
      settings = {
        opener = {
          edit = [
            {
              run = "${lib.getExe myconfig.user.editor.default.pkg} %s";
              block = true;
              desc = "Editor";
              for = "unix";
            }
          ];
        };
      };
    };
  };
}
