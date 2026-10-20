{ delib, ... }:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.system.nix-output-monitor" ({ pkgs }:
      delib.module {
        name = "osa.system.nix-output-monitor";
        options = { ... }: {
          osa.system.nix-output-monitor.enable = delib.boolOption true;
          # Provides the `nom` binary; channel defaults to nixpkgs-unstable.
          osa.system.nix-output-monitor.pkg = delib.packageOption pkgs.nix-output-monitor;
        };
        nixos.ifEnabled = { cfg, ... }: {
          environment.systemPackages = [ cfg.pkg ];
        };
      }
    ))
  ];
}
