# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  description = "OSA -- reusable denix module library and user-facing interface contract for NixOS + home-manager.";

  outputs =
    inputs:
    let
      evaluated = inputs.nixpkgs.lib.evalModules {
        specialArgs = {
          inherit inputs;
          inherit (inputs) self;
        };
        modules = [
          inputs.flake-file.flakeModules.flake
          ./flake-file.nix
        ];
      };
      base = evaluated.config.outputs inputs;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      packages = inputs.nixpkgs.lib.genAttrs systems (
        system:
        let
          pkgs = import inputs.nixpkgs { inherit system; };
        in
        {
          osa = import ./packages/osa { inherit pkgs; };
          write-flake = evaluated.config.flake-file.apps.write-flake pkgs;
        }
      );
      system = "x86_64-linux";
      pkgs = import inputs.nixpkgs { inherit system; };
    in
    base
    // {
      packages = inputs.nixpkgs.lib.recursiveUpdate (base.packages or { }) packages;
      checks = (base.checks or { }) // {
        ${system} = (base.checks.${system} or { }) // {
          flake-file-in-sync = evaluated.config.flake-file.check-flake-file pkgs;

          osa-cli = pkgs.runCommand "osa-cli-tests" { nativeBuildInputs = [ pkgs.bash ]; } (
            builtins.concatStringsSep "\n" [
              "substitute ${./check/osa-cli.sh} test.sh --replace-fail @osaScript@ ${./scripts/osa/osa.sh} --replace-fail @bash@ ${pkgs.bash}/bin/bash"
              "bash test.sh"
              "touch $out"
            ]
          );

          # Fully evaluate every osa module against the `user.*` interface
          # contract via a mock host (./check/default.nix), forcing the
          # whole NixOS + home-manager config tree -- no real machine
          # needed, and downstream flakes don't see ./check at all.
          modules-eval =
            let
              lib = inputs.nixpkgs.lib;
              findInputsNix = import ./lib/flake-inputs.nix { inherit lib; };
              evaluatedHost =
                (inputs.denix.lib.configurations {
                  moduleSystem = "nixos";
                  homeManagerUser = "nixos";
                  paths = [
                    ./modules
                    ./check
                  ];
                  exclude = findInputsNix.findPaths [
                    ./modules
                    ./check
                  ];
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
    };

  inputs = {
    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        quickshell.follows = "quickshell";
      };
    };
    conflux-icon-theme = {
      url = "github:MoshiurRahmanAdib/Conflux-Icon-Theme";
      flake = false;
    };
    denix = {
      url = "github:yunfachi/denix";
      inputs = {
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
    };
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    driftwm = {
      url = "github:malbiruk/driftwm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    elephant.url = "github:abenz1267/elephant";
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-file.url = "github:vic/flake-file";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri-pkgs = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ntfsplus = {
      url = "github:cmspam/ntfsplus-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plymouth-theme-material = {
      url = "github:krozzzis/plymouth-theme-material";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rip = {
      url = "github:cesarferreira/rip";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    silentSDDM = {
      url = "github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    walker = {
      url = "github:abenz1267/walker";
      inputs.elephant.follows = "elephant";
    };
    winapps = {
      url = "github:winapps-org/winapps";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
    };
  };
}
