{ delib, lib, ... }:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.apps.steam" (
      { pkgs }:
      delib.module {
        name = "osa.apps.steam";

        options.osa.apps.steam = {
          enable = delib.boolOption false;
          pkg = delib.packageOption pkgs.steam;
          protonGe = delib.description (delib.boolOption true)
            "Expose GE-Proton as a Steam Play compatibility tool.";
          gamemode = delib.description (delib.boolOption true)
            "Install GameMode so games can request performance boosts on demand.";
          firewall = delib.description (delib.boolOption true)
            "Open the firewall ports Steam needs for Remote Play and local network game transfers.";
        };

        # Steam needs the system graphics stack rather than a home profile:
        # the module turns on 32-bit hardware acceleration, registers the
        # controller udev rules and wires 32-bit audio through PipeWire.
        nixos.ifEnabled = { cfg, ... }: {
          programs.steam = {
            enable = true;
            package = cfg.pkg;
            remotePlay.openFirewall = cfg.firewall;
            localNetworkGameTransfers.openFirewall = cfg.firewall;
            extraCompatPackages = lib.optionals cfg.protonGe [ pkgs.proton-ge-bin ];
          };

          programs.gamemode.enable = cfg.gamemode;
        };
      }
    ))
  ];
}
