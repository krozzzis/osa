{ delib, ... }:
delib.module {
  name = "osa.shell.fzf";

  options = { ... }: {
    osa.shell.fzf.enable = delib.boolOption false;
  };

  home.ifEnabled = {
    programs.fzf.enable = true;
  };
}
