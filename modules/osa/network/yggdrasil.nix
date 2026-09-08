{ delib, ... }:
delib.module {
  name = "osa.network.yggdrasil";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    services.yggdrasil.enable = true;
  };
}
