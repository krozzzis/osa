{
  delib,
  ...
}:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.system.wireguard" ({ pkgs }:
      delib.module {
        name = "osa.system.wireguard";

        options = {...}: {
          osa.system.wireguard.enable = delib.singleEnableOption false;
          osa.system.wireguard.pkg = delib.packageOption pkgs.wireguard-tools;
          osa.system.wireguard.extraPorts = delib.listOption [ ];
        };

        # Interfaces and keys are configured per host downstream via
        # networking.wireguard; OSA only installs the tooling and opens ports.
        nixos.ifEnabled = { cfg, ... }: {
          environment.systemPackages = [ cfg.pkg ];

          networking.firewall.allowedUDPPorts = cfg.extraPorts;
        };
      }
    ))
  ];
}
