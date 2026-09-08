{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.shell.killall";

  options = { myconfig, ... }: {
    osa.shell.killall.enable = delib.boolOption myconfig.user.shell.enable;
  };

  home.ifEnabled = {
    home.packages = with pkgs; [
      psmisc
    ];
  };
}
