# Build both independent completion pipelines with stable and unstable Fish.
{ inputs, system }:
let
  pkgs = import inputs.nixpkgs-stable { inherit system; };
  unstable = import inputs.nixpkgs-unstable { inherit system; };
  systemCompletion =
    fish:
    let
      host = inputs.nixpkgs-stable.lib.nixosSystem {
        inherit system;
        modules = [
          (import ../compat/fish.nix { nixpkgs = inputs.nixpkgs-stable; })
          ({ lib, ... }: {
            system.stateVersion = "26.05";
            documentation.enable = false;
            environment.systemPackages = lib.mkForce [
              pkgs.accountsservice
              unstable.bat
              fish
            ];
            programs.fish = {
              enable = true;
              package = fish;
              generateCompletions = true;
            };
          })
        ];
      };
    in
    host.config.environment.etc."fish/generated_completions".source;
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
  test -s ${systemCompletion pkgs.fish}/bat.fish
  test -s ${systemCompletion unstable.fish}/bat.fish
  touch "$out"
''
