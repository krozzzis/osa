{ lib, ... }: {
  flake-file.inputs = {
    nixpkgs-stable.url = lib.mkDefault "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = lib.mkDefault "github:nixos/nixpkgs/nixos-unstable";
  };
}
