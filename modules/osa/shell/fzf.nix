{ delib, ... }:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.shell.fzf" (
      { pkgs }:
      delib.module {
        name = "osa.shell.fzf";

        options = { ... }: {
          osa.shell.fzf.enable = delib.boolOption false;
        };

        home.ifEnabled = {
          programs.fzf.enable = true;
          programs.fzf.package = pkgs.fzf;
        };
      }
    ))
  ];
}
