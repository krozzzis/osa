{ delib, lib, ... }:
delib.module {
  name = "osa.de.input";

  nixos.always =
    { myconfig, ... }:
    lib.mkIf myconfig.user.gui.enable {
      services.xserver.xkb = {
        inherit (myconfig.user.input.keyboard) layout options;
      };
    };
}
