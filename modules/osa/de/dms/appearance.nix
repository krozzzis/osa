{ delib, ... }:
delib.module {
  name = "osa.de.dms";

  myconfig.ifEnabled = { myconfig, ... }: {
    osa.de.dms.settings = {
      cornerRadius = myconfig.osa.ui.cornerRadius;
      frameRounding = myconfig.osa.ui.frameRounding;
      niriLayoutGapsOverride = myconfig.osa.ui.gap;
      niriLayoutRadiusOverride = myconfig.osa.ui.cornerRadius;
      hyprlandLayoutGapsOverride = myconfig.osa.ui.gap;
      hyprlandLayoutGapsOutOverride = myconfig.osa.ui.gap;
      hyprlandLayoutRadiusOverride = myconfig.osa.ui.cornerRadius;
      currentThemeName = "dynamic";
      currentThemeCategory = "dynamic";
      matugenTemplateHyprland = false;
      matugenTemplateMangowc = false;
      popupTransparency = myconfig.osa.ui.transparency;
      dockTransparency = myconfig.osa.ui.transparency;
      desktopClockTransparency = myconfig.osa.ui.transparency;
      systemMonitorTransparency = myconfig.osa.ui.transparency;
      blurEnabled = true;
      fontFamily = myconfig.user.fonts.regular.name;
      monoFontFamily = myconfig.user.fonts.monospace.name;
    };
  };
}
