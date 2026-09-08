{
  delib,
  inputs,
  ...
}:
delib.module {
  name = "osa.system.ntfs";

  options = delib.singleEnableOption false;

  nixos.always.imports = [ inputs.ntfsplus.nixosModules.default ];

  nixos.ifEnabled = {
    services.ntfsplus.enable = true;
  };
}
