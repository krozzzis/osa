# A NixOS module cannot switch its own module tree after evaluation starts.
# Probe the OSA selector first, then evaluate with the selected Nixpkgs modules.
{ inputs }:
args:
let
  lib = inputs.nixpkgs.lib;
  sources = import ./nixpkgs-sources.nix { inherit inputs; };
  homeManagerSources = lib.filterAttrs (
    name: _: name == "home-manager" || lib.hasPrefix "home-manager-" name
  ) inputs;
  configurations = lib.mapAttrs (
    channel: nixpkgs:
    let
      release = lib.trim (builtins.readFile "${nixpkgs}/.version");
      candidates = lib.filter (source: (lib.importJSON "${source}/release.json").release == release) (
        lib.optional (builtins.hasAttr "home-manager-${channel}" inputs) inputs."home-manager-${channel}"
        ++ builtins.attrValues homeManagerSources
      );
      home-manager =
        if candidates != [ ] then
          builtins.head candidates
        else
          throw "OSA: add a home-manager-<channel> input for Home Manager release ${release} to match nixpkgs channel ${channel}.";
    in
    inputs.denix.lib.configurations (
      args
      // {
        inherit nixpkgs home-manager;
        homeManagerNixpkgs = nixpkgs;
        specialArgs = (args.specialArgs or { }) // {
          inputs = inputs // {
            inherit nixpkgs home-manager;
          };
        };
      }
    )
  ) sources;
in
lib.mapAttrs (
  name: cfg: configurations.${cfg.config.myconfig.osa.system.nixpkgs}.${name}
) configurations.system
