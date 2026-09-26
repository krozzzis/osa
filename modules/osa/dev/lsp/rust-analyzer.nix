{ delib, ... }:
{
  imports = [
    ((import ../../../../lib/package-module.nix) "osa.dev.lsp.rust-analyzer" (
      { pkgs }:
      delib.module {
        name = "osa.dev.lsp.rust-analyzer";

        options = delib.singleEnableOption false;

        myconfig.ifEnabled = {
          user.dev.lsp."rust-analyzer" = {
            enable = true;
            package = pkgs.rust-analyzer;
            settings = {
              checkOnSave = true;
              check.command = "clippy";
            };
          };
        };

        home.ifEnabled = {
          home.packages = with pkgs; [
            rust-analyzer
            rustc
            cargo
          ];
        };
      }
    ))
  ];
}
