{ lib, ... }:
{
  # Keep Nyx's own locked nixpkgs: following our channels changes kernel hashes
  # and loses the upstream binary cache.
  flake-file.inputs.chaotic.url = lib.mkDefault "github:chaotic-cx/nyx/nyxpkgs-unstable";
}
