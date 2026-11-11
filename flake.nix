{
  description = "OSA -- reusable denix module library and user-facing interface contract for NixOS + home-manager.";

  outputs =
    inputs:
    let
      lib = inputs.nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = import inputs.nixpkgs { inherit system; };
    in
    {
      packages = lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system: {
        osa = import ./packages/osa { pkgs = import inputs.nixpkgs { inherit system; }; };
      });

      checks.${system} = {
        oo7-pam = import ./lib/checks/oo7-pam.nix { inherit inputs system; };
        fish-completions = import ./lib/checks/fish-completions.nix { inherit inputs system; };
        osa-cli = pkgs.runCommand "osa-cli-tests" { nativeBuildInputs = [ pkgs.bash ]; } (
          builtins.concatStringsSep "\n" [
            "substitute ${./check/osa-cli.sh} test.sh --replace-fail @osaScript@ ${./scripts/osa/osa.sh} --replace-fail @elevationScript@ ${./scripts/osa/elevate.sh} --replace-fail @bash@ ${pkgs.bash}/bin/bash"
            "bash test.sh"
            "touch $out"
          ]
        );
        modules-eval =
          let
            evaluatedConfiguration =
              moduleSystem: channel:
              (
                (import ./lib/configurations.nix {
                  inputs = inputs // {
                    nixpkgs-pinned-test = inputs.nixpkgs-stable;
                  };
                })
                  {
                    inherit moduleSystem;
                    homeManagerUser = "nixos";
                    paths = [
                      ./modules
                      ./check
                    ];
                    extensions = with inputs.denix.lib.extensions; [
                      args
                      (base.withConfig { args.enable = true; })
                    ];
                    specialArgs = { inherit inputs; };
                    extraModules = [
                      {
                        myconfig.osa.system.nixpkgs = channel;
                        myconfig.osa.system.cachyos.enable = channel == "stable";
                      }
                    ];
                  }
              ).${if moduleSystem == "home" then "nixos@eval-check" else "eval-check"};
            evaluatedHost =
              channel: (evaluatedConfiguration "nixos" channel).config.system.build.toplevel.drvPath;
            evaluatedHome = channel: (evaluatedConfiguration "home" channel).activationPackage.drvPath;
          in
          pkgs.runCommand "osa-modules-eval" { } (
            assert lib.all (channel: builtins.isString (evaluatedHost channel)) [
              "stable"
              "unstable"
            ];
            assert lib.all (channel: builtins.isString (evaluatedHome channel)) [
              "stable"
              "unstable"
            ];
            "touch $out"
          );
      };
    };

  inputs = {
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    conflux-icon-theme = {
      url = "github:MoshiurRahmanAdib/Conflux-Icon-Theme";
      flake = false;
    };
    dankcalendar = {
      url = "github:AvengeMedia/dankcalendar";
    };
    denix = {
      url = "github:yunfachi/denix";
      inputs = {
        home-manager.follows = "home-manager";
      };
    };
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
    };
    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry";
    };
    elephant.url = "github:abenz1267/elephant";
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
    };
    home-manager-stable = {
      url = "github:nix-community/home-manager/release-26.05";
    };
    kkfetch = {
      url = "github:kk376/kkfetch";
    };
    koala-clash = {
      url = "github:endotrizine/koala-clash-nix";
    };
    niri-pkgs = {
      url = "github:sodiboo/niri-flake";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixvim = {
      url = "github:nix-community/nixvim";
    };
    ntfsplus = {
      url = "github:cmspam/ntfsplus-flake";
    };
    plymouth-theme-material = {
      url = "github:krozzzis/plymouth-theme-material";
    };
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
    };
    rip = {
      url = "github:cesarferreira/rip";
    };
    silentSDDM = {
      url = "github:uiriansan/SilentSDDM";
    };
    walker = {
      url = "github:abenz1267/walker";
      inputs.elephant.follows = "elephant";
    };
    winapps = {
      url = "github:winapps-org/winapps";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        home-manager.follows = "home-manager";
      };
    };
  };
}
