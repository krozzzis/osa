{ delib, lib, ... }:
delib.module {
  name = "osa.de.niri.shakeToFind";

  options = delib.singleEnableOption false;

  home.always = { myconfig, ... }: {
    imports = [
      (
        { config, pkgs, ... }:
        lib.mkIf (myconfig.osa.de.niri.enable && myconfig.osa.de.niri.shakeToFind.enable) (
          let
            shakeConfig = pkgs.writeText "niri-shake-to-find.kdl" ''
              cursor {
                  shake {
                      on
                  }
              }
            '';
            niriConfig = ''
              include "${shakeConfig}"
              ${config.programs.niri.finalConfig}
            '';
          in
          {
            # niri-flake has no typed cursor.shake option yet. Include a small
            # fragment and validate the complete config with the patched Niri.
            xdg.configFile.niri-config.source = lib.mkForce (
              pkgs.runCommand "niri-config-with-shake-to-find"
                {
                  inherit niriConfig;
                  passAsFile = [ "niriConfig" ];
                  nativeBuildInputs = [ myconfig.osa.de.niri.pkg ];
                }
                ''
                  niri validate -c "$niriConfigPath"
                  cp "$niriConfigPath" "$out"
                ''
            );
          }
        )
      )
    ];
  };
}
