{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.shell.dnsutils";

  options = { myconfig, ... }: {
    osa.shell.dnsutils.enable = delib.boolOption myconfig.user.shell.enable;
  };

  nixos.ifEnabled = {
    environment.systemPackages = with pkgs; [
      dnsutils
    ];
  };
}
