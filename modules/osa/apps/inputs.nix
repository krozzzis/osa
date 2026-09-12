# For osa/apps/walker.nix (elephant, walker) and osa/apps/winapps.nix (winapps).
{ ... }:
{
  flake-file.inputs = {
    elephant.url = "github:abenz1267/elephant";

    koala-clash = {
      url = "github:endotrizine/koala-clash-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    walker = {
      url = "github:abenz1267/walker";
      inputs.elephant.follows = "elephant";
    };

    winapps = {
      url = "github:winapps-org/winapps";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
