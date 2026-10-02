{ delib, lib, ... }:
delib.module {
  name = "osa.de.niri.shakeToFind";

  options = delib.singleEnableOption false;

  home.always = { myconfig, ... }: {
    imports = lib.optional
      (myconfig.osa.de.niri.enable && myconfig.osa.de.niri.shakeToFind.enable)
      ({ ... }: {
        programs.niri.settings.cursor.shake.on = true;
      });
  };
}
