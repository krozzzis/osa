{
  delib,
  inputs,
  ...
}:
{
  imports = [
    ((import ../../../../lib/package-module.nix) "osa.editor.nixvim" (
      { pkgs }:
      delib.module {
        name = "osa.editor.nixvim";

        options = { myconfig, ... }: {
          osa.editor.nixvim.enable = delib.boolOption myconfig.user.shell.enable;

          osa.editor.nixvim.pkg = delib.packageOption pkgs.neovim;
        };

        # Dependency flakes' nixConfig is not inherited by the consuming flake.
        nixos.ifEnabled.nix.settings = {
          extra-substituters = [ "https://nix-community.cachix.org" ];
          extra-trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];
        };

        home.always.imports = [
          inputs.nixvim.homeModules.nixvim
        ];

        home.ifEnabled = { cfg, ... }: {
          programs.nixvim = {
            enable = true;
            package = cfg.pkg.unwrapped or cfg.pkg;
            nixpkgs.pkgs = pkgs;
          };
        };
      }
    ))
  ];
}
