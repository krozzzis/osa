{ delib, ... }:
{
  imports = [
    ((import ../../../../lib/package-module.nix) "osa.dev.lsp.clangd" (
      { pkgs }:
      delib.module {
        name = "osa.dev.lsp.clangd";

        options = delib.singleEnableOption false;

        myconfig.ifEnabled = {
          user.dev.lsp.clangd = {
            enable = true;
            package = pkgs.clang-tools;
            settings = { };
          };
        };

        home.ifEnabled = {
          home.packages = [ pkgs.clang-tools ];
        };
      }
    ))
  ];
}
