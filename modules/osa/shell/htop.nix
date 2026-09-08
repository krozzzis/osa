{ delib, ... }:
delib.module {
  name = "osa.shell.htop";

  options = { myconfig, ... }: {
    osa.shell.htop.enable = delib.boolOption myconfig.user.shell.enable;
  };

  home.ifEnabled = {
    programs.htop = {
      enable = true;
    };
  };
}
