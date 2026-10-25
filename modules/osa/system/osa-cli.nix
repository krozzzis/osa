{
  delib,
  pkgs,
  inputs,
  config,
  ...
}:
let
  sources = import ../../../lib/nixpkgs-sources.nix { inherit inputs; };
  # Only explicit settings: normalized pkgs.config includes defaults
  # whose types can differ between nixpkgs releases.
  unstable = import sources.unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config = config.nixpkgs.config;
  };
  # nh comes from nixpkgs-unstable regardless of the system channel,
  # while the osa CLI itself keeps following the module package set.
  package = import ../../../packages/osa {
    inherit pkgs;
    nh = unstable.nh;
  };
in
delib.module {
  name = "osa.system.osa-cli";

  options = { ... }: {
    osa.system.osa-cli.enable = delib.boolOption true;
    osa.system.osa-cli.pkg = delib.packageOption package;
  };

  nixos.ifEnabled = { cfg, ... }: {
    environment.systemPackages = [ cfg.pkg ];
  };
}
