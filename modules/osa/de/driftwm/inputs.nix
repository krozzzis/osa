# For osa/de/driftwm.
{ ... }:
{
  flake-file.inputs = {
    driftwm = {
      url = "github:malbiruk/driftwm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
