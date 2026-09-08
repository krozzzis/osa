{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.shell.fd";

  options = { myconfig, ... }: {
    osa.shell.fd.enable = delib.boolOption myconfig.user.shell.enable;
  };

  home.ifEnabled = {
    home.packages = with pkgs; [
      fd
    ];
  };
}
