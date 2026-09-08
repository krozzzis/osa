{
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.de.driftwm";

  options = { ... }: {
    osa.de.driftwm.enable = delib.boolOption false;
    osa.de.driftwm.launcher.default = lib.mkOption {
      type = lib.types.attrs;
      default = {
        pkg = pkgs.walker;
      };
    };
  };

  nixos.always.imports = [ inputs.driftwm.nixosModules.default ];

  nixos.ifEnabled = {
    programs.driftwm = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };
  };
}
