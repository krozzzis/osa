{
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.apps.cosmic";

  options = { ... }: {
    osa.apps.cosmic = {
      enable = delib.boolOption false;
      files = delib.description (delib.boolOption true) "Cosmic file manager";
      reader = {
        enable = delib.description (delib.boolOption true) "Cosmic document reader";
        pkg = delib.packageOption (pkgs.cosmic-reader);
      };
      calculator = delib.description (delib.boolOption true) "Cosmic calculator";
      player = delib.description (delib.boolOption true) "Cosmic media player";
      workspaces = delib.description (delib.boolOption false) "Cosmic workspaces epoch";
    };
  };

  home.ifEnabled =
    { cfg, ... }:
    let
      packages =
        with pkgs;
        (
          (lib.optionals cfg.files [ cosmic-files ])
          ++ (lib.optionals cfg.reader.enable [ cfg.reader.pkg ])
          ++ (lib.optionals cfg.calculator [ cosmic-ext-calculator ])
          ++ (lib.optionals cfg.player [ cosmic-player ])
          ++ (lib.optionals cfg.workspaces [ cosmic-workspaces-epoch ])
        );
    in
    {
      home.packages = packages;
    };
}
