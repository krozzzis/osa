{
  delib,
  inputs,
  ...
}:
delib.module {
  name = "osa.system.optimize";

  options = { ... }: {
    osa.system.optimize.enable = delib.boolOption true;
  };

  nixos.ifEnabled = { ... }: {
    boot.kernelParams = [ "nowatchdog" ];

    boot.loader.systemd-boot.configurationLimit = 4;

    nix.settings.min-free = 5 * 1024 * 1024 * 1024;

    services.btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
    };

    services.journald =
      if inputs.nixpkgs.lib.versionAtLeast inputs.nixpkgs.lib.version "26.11" then
        {
          settings.Journal.Storage = "volatile";
        }
      else
        {
          extraConfig = "Storage=volatile";
        };

    systemd.settings.Manager.DefaultTimeoutStopSec = "10s";

    networking.networkmanager.dns = "systemd-resolved";
    services.resolved.enable = true;

    boot.kernel.sysctl."vm.swappiness" = 10;

    systemd.oomd.enable = true;

    services.irqbalance.enable = true;
  };
}
