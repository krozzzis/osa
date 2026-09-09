{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.browser.chromium";

  options = {
    osa.browser.chromium = {
      enable = delib.boolOption false;
      pkg = delib.packageOption pkgs.chromium;
    };
  };

  # Keep Chromium in the system profile rather than a user's Home Manager
  # profile. This makes `chromium` available to every user, including
  # non-login automation agents such as Codex.
  nixos.ifEnabled = { cfg, ... }: {
    environment.systemPackages = [ cfg.pkg ];
  };
}
