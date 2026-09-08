{
  delib,
  inputs,
  ...
}:
delib.module {
  name = "osa.system.sddm";

  options = delib.singleEnableOption false;

  nixos.always.imports = [ inputs.silentSDDM.nixosModules.default ];

  nixos.ifEnabled = {
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    security.pam.services.sddm.enableGnomeKeyring = true;

    programs.silentSDDM = {
      enable = true;
      theme = "rei";
      # settings = { ... }; see example in module
    };
  };
}
