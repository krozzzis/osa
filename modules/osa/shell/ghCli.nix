{
  delib,
  ...
}:
delib.module {
  name = "osa.shell.ghCli";

  options = { myconfig, ... }: {
    osa.shell.ghCli.enable = delib.boolOption myconfig.user.shell.enable;
  };

  home.ifEnabled = {
    programs.gh = {
      enable = true;

      gitCredentialHelper = {
        enable = true;
      };
    };
  };
}
