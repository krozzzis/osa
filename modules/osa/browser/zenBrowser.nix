{
  delib,
  lib,
  pkgs,
  inputs,
  ...
}:
delib.module {
  name = "osa.browser.zenBrowser";

  options = { myconfig, ... }: {
    osa.browser.zenBrowser.enable = delib.boolOption myconfig.user.gui.enable;
    osa.browser.zenBrowser.pkg = delib.packageOption pkgs.firefox;
  };

  home.always.imports = [ ];

  nixos.ifEnabled = {
    environment.sessionVariables = {
      MOZ_USE_XINPUT2 = "1";
    };
  };

  home.ifEnabled = {
    # Use firefox as fallback until zen-browser flake supports ffmpeg_8 (nixpkgs c043)
    programs.firefox.enable = lib.mkDefault true;
  };
}
