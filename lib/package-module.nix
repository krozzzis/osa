# Keep the package universe local to an application (including its plugins).
# In particular, do not overlay unstable packages onto the system package set.
name: factory:
{
  config,
  lib,
  inputs,
  ...
}:
let
  path = lib.splitString "." name;
  channel = lib.getAttrFromPath (path ++ [ "nixpkgs" ]) config.myconfig;
in
{
  options.myconfig = lib.setAttrByPath (path ++ [ "nixpkgs" ]) (
    lib.mkOption {
      type = lib.types.enum (builtins.attrNames (import ./nixpkgs-sources.nix { inherit inputs; }));
      default = config.myconfig.osa.nixpkgs.default;
      description = "Nixpkgs channel for ${name}; pkg overrides still take precedence.";
    }
  );
  imports = [ (factory { pkgs = config.myconfig.osa.nixpkgs.packages.${channel}; }) ];
}
