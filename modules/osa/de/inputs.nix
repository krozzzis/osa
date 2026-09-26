# For osa/de/caelestia.nix.
{ ... }:
{
  flake-file.inputs = {
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.quickshell.follows = "quickshell";
    };
  };
}
