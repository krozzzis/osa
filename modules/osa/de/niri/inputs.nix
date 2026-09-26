{ ... }:
{
  flake-file.inputs.niri-pkgs = {
    url = "github:sodiboo/niri-flake";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };
}
