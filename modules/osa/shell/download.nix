{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.shell.download";

  options = { myconfig, ... }: {
    osa.shell.download.enable = delib.boolOption myconfig.user.shell.enable;
  };

  nixos.ifEnabled = {
    environment.systemPackages = with pkgs; [
      wget
      curl
      rsync
    ];
  };
}
