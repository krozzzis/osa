# For osa/de/caelestia.nix.
{ ... }:
{
  flake-file.inputs = {
    driftwm = {
      url = "github:malbiruk/driftwm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
