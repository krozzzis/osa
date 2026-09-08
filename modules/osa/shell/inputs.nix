{ ... }:
{
  flake-file.inputs.rip = {
    url = "github:cesarferreira/rip";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
