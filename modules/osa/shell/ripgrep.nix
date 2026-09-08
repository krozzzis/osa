{ delib, ... }:
delib.module {
  name = "osa.shell.ripgrep";

  options = { myconfig, ... }: {
    osa.shell.ripgrep.enable = delib.boolOption myconfig.user.shell.enable;
  };

  home.ifEnabled = {
    programs.ripgrep = {
      enable = true;
    };
  };
}
