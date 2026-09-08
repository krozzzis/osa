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

  home.ifEnabled =
    { myconfig, ... }:
    let
      editor =
        myconfig.user.editor.default.pkg.meta.mainProgram or (lib.getName myconfig.user.editor.default.pkg);
    in
    {
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
                # Keep Yazi on the activated editor wrapper. An absolute Nix
                # store path can outlive its plugin set after a profile update.
                run = "${editor} %s";
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
