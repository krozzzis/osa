# Every top-level nixpkgs-<channel> flake input is an available channel.
# Downstream can add named releases without changing OSA's module schema.
{ inputs }:
let
  lib = inputs.nixpkgs.lib;
in
(lib.mapAttrs' (name: source: lib.nameValuePair (lib.removePrefix "nixpkgs-" name) source) (
  lib.filterAttrs (name: _: lib.hasPrefix "nixpkgs-" name) inputs
))
// {
  system = inputs.nixpkgs;
}
