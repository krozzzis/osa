{
  delib,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  sources = import ../../../lib/nixpkgs-sources.nix { inherit inputs; };
  channelType = lib.types.enum (builtins.attrNames sources);
in
delib.module {
  name = "osa.nixpkgs";
  options = {
    osa.system.nixpkgs = lib.mkOption {
      type = channelType;
      default = "system";
      description = "System module and package source, applied by OSA lib/configurations.nix.";
    };
    osa.nixpkgs = {
      default = lib.mkOption {
        type = channelType;
        default = "unstable";
        description = "Default channel for application modules.";
      };
      packages = lib.mkOption {
        type = lib.types.raw;
        readOnly = true;
        default = lib.mapAttrs (
          name: source:
          if name == "system" then
            pkgs
          else
            import source {
              inherit (pkgs.stdenv.hostPlatform) system;
              # Only explicit settings: normalized pkgs.config includes defaults
              # whose types can differ between nixpkgs releases.
              config = config.nixpkgs.config;
            }
        ) sources;
        description = "Shared package sets without system overlays, preserving upstream cache identities.";
      };
    };
  };
}
