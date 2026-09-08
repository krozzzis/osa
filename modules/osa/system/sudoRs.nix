{ delib, ... }:

delib.module {
  name = "osa.system.sudoRs";

  options = delib.singleEnableOption true;

  nixos.ifEnabled = {
    security.sudo-rs.enable = true;
  };
}
