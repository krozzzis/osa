{
  delib,
  inputs,
  ...
}:
delib.module {
  name = "osa.system.sddm";

  options = delib.singleEnableOption false;

  myconfig.ifEnabled.osa.system.oo7.enable = true;

  nixos.always.imports = [ inputs.silentSDDM.nixosModules.default ];

  nixos.ifEnabled = {
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    security.pam.services.sddm.oo7.enable = true;

    programs.silentSDDM = {
      enable = true;
      theme = "rei";
      # settings = { ... }; see example in module
    };
  };
}
