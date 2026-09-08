{
  delib,
  ...
}:
delib.module {
  name = "osa.apps.throne";

  options = { myconfig, ... }: {
    osa.apps.throne = {
      enable = delib.boolOption myconfig.user.gui.enable;
      tunMode = delib.description (delib.boolOption true) "Enable TUN mode for VPN";
    };
  };

  nixos.ifEnabled = { cfg, ... }: {
    programs.throne = {
      enable = true;
      tunMode.enable = cfg.tunMode;
    };
  };
}
