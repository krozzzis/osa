{ lib, ... }: {
  flake-file.inputs = {
    nixpkgs-stable.url = lib.mkDefault "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = lib.mkDefault "github:nixos/nixpkgs/nixos-unstable";
    home-manager-stable = {
      url = lib.mkDefault "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
  };
}
