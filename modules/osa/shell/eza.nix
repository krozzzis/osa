{ delib, ... }:
delib.module {
  # ls replacement
  name = "osa.shell.eza";

  options = { myconfig, ... }: {
    osa.shell.eza.enable = delib.boolOption myconfig.user.shell.enable;
  };

  home.ifEnabled = {
    programs.eza = {
      enable = true;
    };

    home = {
      shellAliases = {
        l = "eza --icons --no-permissions --no-user";
        ls = "eza --icons";
        la = "eza -la --icons";
        ll = "eza -l --icons";
        lt = "eza -l --tree";
      };
    };
  };
}
