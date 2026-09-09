{ pkgs }:
pkgs.writeShellApplication {
  name = "osa";
  runtimeInputs = with pkgs; [
    coreutils
    nix
    nixos-rebuild
    sudo
  ];
  text = builtins.readFile ../../scripts/osa/osa.sh;
}
