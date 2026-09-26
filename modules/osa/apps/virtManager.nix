{
  delib,
  ...
}:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.apps.virtManager" (
      { pkgs }:
      delib.module {
        name = "osa.apps.virtManager";

        options = { myconfig, ... }: {
          osa.apps.virtManager.enable = delib.boolOption myconfig.user.gui.enable;
        };

        nixos.ifEnabled = { myconfig, ... }: {
          programs.virt-manager.enable = true;
          programs.virt-manager.package = pkgs.virt-manager;

          virtualisation.libvirtd.enable = true;
          users.users.${myconfig.user.constants.username}.extraGroups = [ "libvirtd" ];
        };
      }
    ))
  ];
}
