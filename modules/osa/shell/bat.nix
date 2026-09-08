{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.shell.bat";

  options = { myconfig, ... }: {
    osa.shell.bat.enable = delib.boolOption myconfig.user.shell.enable;
  };

  home.ifEnabled = {
    home.packages = with pkgs; [
      bat
    ];
  };
}
