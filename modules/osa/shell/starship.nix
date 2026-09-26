{ delib, lib, ... }:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.shell.starship" (
      { pkgs }:
      delib.module {
        name = "osa.shell.starship";

        options = { myconfig, ... }: {
          osa.shell.starship.enable = delib.boolOption myconfig.user.shell.enable;
          osa.shell.starship.useNerdFonts = delib.description (delib.boolOption true) "Enable Nerd Font icons for modules";
        };

        myconfig.ifEnabled =
          { myconfig, ... }:
          let
            cfg = myconfig.osa.shell.starship;
          in
          lib.mkIf cfg.useNerdFonts {
            user.gui.fonts.nerdfonts = true;
          };

        # Prompt format/theme is personal taste -- see modules/dotfiles/starship.nix
        # in the osa-user flake, which extends this same module by name.
        home.ifEnabled = {
          programs.starship.enable = true;
          programs.starship.package = pkgs.starship;
        };
      }
    ))
  ];
}
