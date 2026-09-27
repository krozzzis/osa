{ delib, ... }:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.taskManager.missionCenter" (
      { pkgs }:
      delib.module {
        name = "osa.taskManager.missionCenter";
        options.osa.taskManager.missionCenter = {
          enable = delib.boolOption false;
          desktop = delib.strOption "io.missioncenter.MissionCenter.desktop";
          pkg = delib.packageOption pkgs.mission-center;
        };
        home.ifEnabled = { cfg, ... }: { home.packages = [ cfg.pkg ]; };
      }
    ))
  ];
}
