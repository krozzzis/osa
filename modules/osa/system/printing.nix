{
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.system.printing";

  options = { myconfig, ... }: {
    osa.system.printing = {
      enable = delib.boolOption false;
      gui = delib.description (delib.boolOption myconfig.user.gui.enable) "Install the graphical CUPS administration tool";
      drivers = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = with pkgs; [
          brlaser
          gutenprint
          hplip
          splix
        ];
        description = "CUPS printer driver packages.";
      };
    };
  };

  nixos.ifEnabled = { cfg, ... }: {
    services.printing = {
      enable = true;
      browsed.enable = true;
      drivers = cfg.drivers;
    };

    # Most modern network printers announce driverless IPP queues over mDNS.
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    programs.system-config-printer.enable = cfg.gui;
  };
}
