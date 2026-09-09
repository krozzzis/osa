{
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.shell.git";

  options = { myconfig, ... }: {
    osa.shell.git.enable = delib.boolOption myconfig.user.shell.enable;
  };

  home.ifEnabled =
    { myconfig, ... }:
    let
      editor =
        myconfig.user.editor.default.pkg.meta.mainProgram or (lib.getName myconfig.user.editor.default.pkg);
    in
    {
      programs.git = {
        enable = true;
        lfs.enable = true;

        settings.user.name = myconfig.user.constants.username;
        settings.user.email = myconfig.user.constants.useremail;
        # Resolve the editor through PATH. Nixvim installs a configured wrapper
        # there, while its package option points at the unwrapped Neovim used to
        # build that wrapper. Calling the store path directly makes bare Neovim
        # load Nixvim's generated config without its plugins.
        settings.core.editor = editor;
      };
    };

  nixos.ifEnabled = {
    environment.systemPackages = with pkgs; [
      git
    ];
  };
}
