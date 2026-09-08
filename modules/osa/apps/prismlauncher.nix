{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.apps.prismlauncher";

  options = { myconfig, ... }: {
    osa.apps.prismlauncher.enable = delib.boolOption myconfig.user.gui.enable;
  };

  home.ifEnabled = {
    home.packages = with pkgs; [
      prismlauncher
    ];
  };
}
