{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.shell.tokei";

  options = { myconfig, ... }: {
    osa.shell.tokei.enable = delib.boolOption myconfig.user.shell.enable;
  };

  home.ifEnabled = {
    home.packages = with pkgs; [
      tokei
    ];
  };
}
