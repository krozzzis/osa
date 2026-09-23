{ delib, pkgs, ... }:
delib.module {
  name = "osa.apps.obsidian";

  options = { myconfig, ... }: {
    osa.apps.obsidian.enable = delib.boolOption myconfig.user.gui.enable;
  };

  home.ifEnabled = {
    home.packages = [ pkgs.obsidian ];

    home.file."Obsidian/.keep".text = "";

    xdg.desktopEntries.obsidian-vault = {
      name = "Obsidian (personal vault)";
      comment = "Open the Obsidian vault in ~/Obsidian";
      exec = "obsidian --vault=Obsidian";
      icon = "obsidian";
      terminal = false;
      categories = [ "Office" ];
    };
  };
}
