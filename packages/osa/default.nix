{ pkgs }:
let
  package = pkgs.writeShellApplication {
    name = "osa";
    runtimeInputs = with pkgs; [
      coreutils
      nix
      nixos-rebuild
      sudo
      systemd
    ];
    text = builtins.readFile ../../scripts/osa/osa.sh;
  };
in
package.overrideAttrs (old: {
  buildCommand = old.buildCommand + ''
    install -Dm444 ${./completions/osa.bash} \
      $out/share/bash-completion/completions/osa
    install -Dm444 ${./completions/_osa} \
      $out/share/zsh/site-functions/_osa
    install -Dm444 ${./completions/osa.fish} \
      $out/share/fish/vendor_completions.d/osa.fish
  '';
})
