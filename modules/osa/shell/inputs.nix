{ ... }:
{
  flake-file.inputs.rip = {
    url = "github:cesarferreira/rip";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  flake-file.inputs.kkfetch = {
    url = "github:kk376/kkfetch";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  flake-file.inputs.nix-index-database = {
    url = "github:nix-community/nix-index-database";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };
}
