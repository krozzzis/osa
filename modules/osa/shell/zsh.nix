{
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.shell.zsh";

  options = { myconfig, ... }: {
    osa.shell.zsh.enable = delib.boolOption (
      myconfig.user.shell.enable
      && myconfig.user.shell.default != null
      && lib.getName myconfig.osa.shell.zsh.pkg == lib.getName myconfig.user.shell.default.pkg
    );
    osa.shell.zsh.pkg = delib.packageOption pkgs.zsh;
  };

  home.ifEnabled = { myconfig, ... }: {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      history.size = 10000;

      initContent = ''
        [[ -z $TMUX ]] || export TERM=screen-256color

        setopt auto_cd

        zstyle ':completion:*' menu select
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        zstyle ':completion:*' completer _complete _ignored

        bindkey '^[[1;5C' forward-word
        bindkey '^[[1;5D' backward-word
        bindkey '^[OC' forward-word
        bindkey '^[OD' backward-word
      '';
    };

    programs.fzf.enableZshIntegration = myconfig.osa.shell.fzf.enable;
  };

  nixos.ifEnabled =
    { ... }:
    {
      programs.zsh.enable = true;
    };
}
