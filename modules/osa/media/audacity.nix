{
  delib,
  ...
}:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.media.audacity" ({ pkgs }:
      delib.module {
        name = "osa.media.audacity";

        # Audacity 4.0.0 cannot build against qtdeclarative 6.12: its
        # generated QML AOT cache output fails AOTLookupValidation. Skip QML
        # cachegen so the incompatible lookup tables are never generated;
        # this costs a little QML startup cache but keeps the build working.
        options = { myconfig, ... }: {
          osa.media.audacity.enable = delib.boolOption myconfig.user.gui.enable;
          osa.media.audacity.pkg = delib.packageOption (
            pkgs.audacity.overrideAttrs (old: {
              cmakeFlags = (old.cmakeFlags or [ ]) ++ [ "-DQT_QML_NO_CACHEGEN=TRUE" ];
            })
          );
        };

        home.ifEnabled = { cfg, ... }: {
          home.packages = [ cfg.pkg ];
        };
      }
    ))
  ];
}
