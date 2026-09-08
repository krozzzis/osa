{
  delib,
  ...
}:
delib.module {
  name = "osa.de.niri";

  home.ifEnabled = { myconfig, ... }: {
    programs.niri.settings.window-rules =
      let
        r = myconfig.osa.ui.cornerRadius * 1.0;
      in
      [
        {
          geometry-corner-radius = {
            top-left = r;
            top-right = r;
            bottom-left = r;
            bottom-right = r;
          };
          clip-to-geometry = true;
        }

        {
          matches = [
            { app-id = "librewolf"; }
            { app-id = "zen"; }
            { app-id = "telegram-desktop"; }
          ];
          open-maximized = true;
        }

        {
          matches = [
            { title = "Extension:"; }
          ];
          open-floating = true;
        }

        {
          matches = [
            { app-id = "scrcpy"; }
          ];
          open-floating = true;
        }
      ];
  };
}
