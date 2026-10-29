{ delib, ... }:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.apps.stm32cubemx" (
      { pkgs }:
      delib.module {
        name = "osa.apps.stm32cubemx";

        options = {
          osa.apps.stm32cubemx.enable = delib.boolOption false;
          osa.apps.stm32cubemx.pkg = delib.packageOption pkgs.stm32cubemx;
        };

        home.ifEnabled =
          { cfg, myconfig, ... }:
          let
            cubeMx = pkgs.symlinkJoin {
              name = "stm32cubemx-configured";
              paths = [ cfg.pkg ];
              nativeBuildInputs = [ pkgs.makeWrapper ];
              postBuild = ''
                wrapProgram "$out/bin/stm32cubemx" \
                  --set _JAVA_AWT_WM_NONREPARENTING 1 \
                  --prefix JAVA_TOOL_OPTIONS " " "-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true -Dsun.java2d.uiScale=${toString myconfig.user.ui.scale}"
              '';
            };
          in
          {
            home.packages = [ cubeMx ];
          };
      }
    ))
  ];
}
