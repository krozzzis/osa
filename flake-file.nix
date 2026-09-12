{ lib, ... }:
let
  flakeInputs = import ./lib/flake-inputs.nix { inherit lib; };
  moduleDirs = [ ./modules ];
in
{
  description = "OSA -- reusable denix module library and user-facing interface contract for NixOS + home-manager.";

  imports = flakeInputs.importModules moduleDirs;

  # `write-flake` writes this exact evalModules shim into flake.nix for us.
  # Based on flake-file's built-in "flake-module" preset (no flake-parts),
  # extended to also expose two bits of flake-file's own machinery that the
  # "flake-module" preset alone drops (it only returns `config.outputs
  # inputs`): `nix run .#write-flake` to regenerate this file, and a
  # `nix flake check` that fails loudly if someone edits flake.nix by hand
  # or forgets to regenerate it after adding an `inputs.nix`.
  flake-file.outputs = ''
    inputs:
      let
        evaluated = inputs.nixpkgs.lib.evalModules {
          specialArgs = { inherit inputs; inherit (inputs) self; };
          modules = [ inputs.flake-file.flakeModules.flake ./flake-file.nix ];
        };
        base = evaluated.config.outputs inputs;
        systems = [ "x86_64-linux" "aarch64-linux" ];
        packages = inputs.nixpkgs.lib.genAttrs systems (
          system:
          let pkgs = import inputs.nixpkgs { inherit system; };
          in {
            osa = import ./packages/osa { inherit pkgs; };
            write-flake = evaluated.config.flake-file.apps.write-flake pkgs;
          }
        );
        system = "x86_64-linux";
        pkgs = import inputs.nixpkgs { inherit system; };
      in
      base // {
        packages = inputs.nixpkgs.lib.recursiveUpdate (base.packages or { }) packages;
        checks = (base.checks or { }) // {
          ''${system} = (base.checks.''${system} or { }) // {
            flake-file-in-sync = evaluated.config.flake-file.check-flake-file pkgs;

            osa-cli = pkgs.runCommand "osa-cli-tests" { nativeBuildInputs = [ pkgs.bash ]; }
              (builtins.concatStringsSep "\n" [
                "substitute ''${./check/osa-cli.sh} test.sh --replace-fail @osaScript@ ''${./scripts/osa/osa.sh} --replace-fail @bash@ ''${pkgs.bash}/bin/bash"
                "bash test.sh"
                "touch $out"
              ]);

            # Fully evaluate every osa module against the `user.*` interface
            # contract via a mock host (./check/default.nix), forcing the
            # whole NixOS + home-manager config tree -- no real machine
            # needed, and downstream flakes don't see ./check at all.
            modules-eval =
              let
                lib = inputs.nixpkgs.lib;
                findInputsNix = import ./lib/flake-inputs.nix { inherit lib; };
                evaluatedHost = (inputs.denix.lib.configurations {
                  moduleSystem = "nixos";
                  homeManagerUser = "nixos";
                  paths = [ ./modules ./check ];
                  exclude = findInputsNix.findPaths [ ./modules ./check ];
                  extensions =
                    let
                      dext = inputs.denix.lib.extensions;
                    in
                    [
                      dext.args
                      (dext.base.withConfig { args.enable = true; })
                    ];
                  specialArgs = { inherit inputs; };
                }).eval-check.config.system.build.toplevel.drvPath;
              in
              pkgs.runCommand "osa-modules-eval" { } (
                assert builtins.isString evaluatedHost;
                "touch $out"
              );
          };
        };
      }
  '';

  # Core, foundational inputs every module effectively depends on
  # transitively (nixpkgs/home-manager/denix), plus flake-file itself.
  # Everything else lives in a sibling `inputs.nix` next to whichever
  # module(s) actually reference `inputs.<name>` -- see ./lib/flake-inputs.nix.
  #
  # Downstream configuration flakes declare the SAME core inputs
  # themselves (chicken-and-egg-exempt bootstrap set) and pull in the rest
  # by running the same collectInputModules scan over `${inputs.osa}/modules`.
  flake-file.inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    denix = {
      url = "github:yunfachi/denix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    flake-file.url = "github:vic/flake-file";
  };

  # This flake is a module library, not a host builder. A downstream flake
  # (for example osa-krozzzis) runs denix.lib.configurations to produce
  # nixosConfigurations. Nothing here needs `inputs` at eval time,
  # so there's no bootstrap chicken-and-egg like flake-file.nix's own
  # `outputs` had to work around.
  outputs = _inputs: { };
}
