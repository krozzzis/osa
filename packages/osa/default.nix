{ pkgs }:
pkgs.writeShellApplication {
  name = "osa";
  runtimeInputs = with pkgs; [
    coreutils
    nix
    nixos-rebuild
    sudo
    systemd
  ];
  text = builtins.readFile ../../scripts/osa/osa.sh;
}
