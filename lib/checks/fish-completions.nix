# Build the completion that exposed the stable-HM/new-Fish incompatibility.
{ inputs, system }:
let
  pkgs = import inputs.nixpkgs-stable { inherit system; };
  unstable = import inputs.nixpkgs-unstable { inherit system; };
  completion =
    fish:
    let
      home = inputs.home-manager-stable.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          (import ../compat/fish.nix { homeManager = inputs.home-manager-stable; })
          {
            home.username = "fish-check";
            home.homeDirectory = "/home/fish-check";
            home.stateVersion = "26.05";
            home.packages = [ unstable.bat ];
            programs.fish = {
              enable = true;
              package = fish;
              generateCompletions = true;
            };
          }
        ];
      };
    in
    builtins.head (
      builtins.filter (p: pkgs.lib.hasPrefix "bat-" p.name) home.config.home.extraDependencies
    );
in
pkgs.runCommand "osa-fish-completions-check" { } ''
  test -s ${completion pkgs.fish}/bat.fish
  test -s ${completion unstable.fish}/bat.fish
  touch "$out"
''
