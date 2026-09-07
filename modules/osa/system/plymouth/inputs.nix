{ ... }:
{
  flake-file.inputs.plymouth-theme-material = {
    url = "github:krozzzis/plymouth-theme-material";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
