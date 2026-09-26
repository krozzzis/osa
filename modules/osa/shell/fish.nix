{
  delib,
  lib,
  ...
}:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.shell.fish" (
      { pkgs }:
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

        home.ifEnabled = { cfg, myconfig, ... }: {
          programs.fish = {
            package = cfg.pkg;
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
          { cfg, ... }:
          {
            programs.fish.enable = true;
            programs.fish.package = cfg.pkg;
          };
      }
    ))
  ];
}
