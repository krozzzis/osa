{ delib, ... }:

delib.module {
  name = "osa.system.ntpdRs";

  options = delib.singleEnableOption true;

  nixos.ifEnabled = {
    services.ntpd-rs.enable = true;
  };
}
