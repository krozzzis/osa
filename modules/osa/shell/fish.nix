{
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.shell.fish";

  options = { myconfig, ... }: {
    osa.shell.fish.enable = delib.boolOption (
      myconfig.user.shell.enable
      && myconfig.user.shell.default != null
      && lib.getName myconfig.osa.shell.fish.pkg == lib.getName myconfig.user.shell.default.pkg
    );
    osa.shell.fish.pkg = delib.packageOption pkgs.fish;
  };

  home.ifEnabled = { myconfig, ... }: {
    programs.fish = {
      enable = true;
      generateCompletions = true;
      shellAliases = myconfig.user.shell.aliases;

      interactiveShellInit = ''
        set fish_greeting # Disable greeting
      '';
    };

    programs.fzf.enableFishIntegration = myconfig.osa.shell.fzf.enable;
  };

  nixos.ifEnabled =
    { ... }:
    {
      programs.fish.enable = true;
    };
}
