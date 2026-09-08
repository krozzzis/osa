{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.apps.wireshark";

  options = { myconfig, ... }: {
    osa.apps.wireshark.enable = delib.boolOption myconfig.user.gui.enable;
  };

  home.ifEnabled = {
    home.packages = with pkgs; [
      wireshark
    ];
  };

  nixos.ifEnabled = { myconfig, ... }: {
    programs.wireshark.enable = true;
    users.users.${myconfig.user.constants.username}.extraGroups = [ "wireshark" ];
  };
}
