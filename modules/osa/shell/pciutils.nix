{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.shell.pciutils";

  options = { myconfig, ... }: {
    osa.shell.pciutils.enable = delib.boolOption myconfig.user.shell.enable;
  };

  nixos.ifEnabled = {
    environment.systemPackages = with pkgs; [
      pciutils
    ];
  };
}
