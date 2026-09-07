{
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.system.optimize";

  options = { myconfig, ... }: {
    osa.system.optimize.enable = delib.boolOption true;
  };

  nixos.ifEnabled = { myconfig, cfg, ... }: {
    boot.kernelParams = [ "nowatchdog" ];

    boot.loader.systemd-boot.configurationLimit = 4;

    nix.settings.min-free = 5 * 1024 * 1024 * 1024;

    services.btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
    };

    services.journald.settings.Journal.Storage = "volatile";

    systemd.settings.Manager.DefaultTimeoutStopSec = "10s";

    networking.networkmanager.dns = "systemd-resolved";
    services.resolved.enable = true;

    boot.kernel.sysctl."vm.swappiness" = 10;

    systemd.oomd.enable = true;

    services.irqbalance.enable = true;
  };
}
