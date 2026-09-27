{ delib, ... }:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.fileManager.flux" (
      { pkgs }:
      delib.module {
        name = "osa.fileManager.flux";
        options.osa.fileManager.flux = {
          enable = delib.boolOption false;
          desktop = delib.strOption "io.github.killown.flux.desktop";
          pkg = delib.packageOption (pkgs.callPackage ../../../packages/flux { });
        };
        nixos.ifEnabled = {
          services.gvfs.enable = true;
          services.udisks2.enable = true;
        };
        home.ifEnabled = { cfg, ... }: { home.packages = [ cfg.pkg ]; };
      }
    ))
  ];
}
