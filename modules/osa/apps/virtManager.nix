{
  delib,
  ...
}:
delib.module {
  name = "osa.apps.virtManager";

  options = { myconfig, ... }: {
    osa.apps.virtManager.enable = delib.boolOption myconfig.user.gui.enable;
  };

  nixos.ifEnabled = { myconfig, ... }: {
    programs.virt-manager.enable = true;

    virtualisation.libvirtd.enable = true;
    users.users.${myconfig.user.constants.username}.extraGroups = [ "libvirtd" ];
  };
}
