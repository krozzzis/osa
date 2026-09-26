# A NixOS module cannot switch its own module tree after evaluation starts.
# Probe the OSA selector first, then evaluate with the selected Nixpkgs modules.
{ inputs }:
args:
let
  lib = inputs.nixpkgs.lib;
  sources = import ./nixpkgs-sources.nix { inherit inputs; };
  configurations = lib.mapAttrs (
    _: nixpkgs:
    inputs.denix.lib.configurations (
      args
      // {
        inherit nixpkgs;
        homeManagerNixpkgs = nixpkgs;
        specialArgs = (args.specialArgs or { }) // {
          inputs = inputs // {
            inherit nixpkgs;
          };
        };
      }
    )
  ) sources;
in
lib.mapAttrs (
  name: cfg: configurations.${cfg.config.myconfig.osa.system.nixpkgs}.${name}
) configurations.system
