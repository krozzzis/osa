{
  delib,
  ...
}:
delib.module {
  name = "osa.apps.kdeconnect";

  options = { myconfig, ... }: {
    osa.apps.kdeconnect.enable = delib.boolOption myconfig.user.gui.enable;
  };

  nixos.ifEnabled = {
    programs.kdeconnect.enable = true;

    networking.firewall = {
      enable = true;
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
    };
  };
}
