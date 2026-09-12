{
  delib,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  materialPackage =
    inputs.plymouth-theme-material.packages.${pkgs.stdenv.hostPlatform.system}.plymouth-theme-material;
  osaMaterialPackage = materialPackage.override {
    settings.palette = {
      background = "#14130b";
      surface = "#211f15";
      outline = "#494632";
      accent = "#e5c75a";
      onSurface = "#eee9cf";
      muted = "#cbc4a5";
      input = "#14130b";
      inputOutline = "#cdbb68";
      badge = "#39351c";
    };
  };
in
delib.module {
  name = "osa.system.plymouth";

  options = { ... }: {
    osa.system.plymouth.enable = delib.boolOption false;
    osa.system.plymouth.pkg = delib.packageOption osaMaterialPackage;
    osa.system.plymouth.theme = lib.mkOption {
      type = lib.types.str;
      default = "material";
      description = "Plymouth theme name. OSA provides its Material You-like 'material' theme by default.";
    };
    osa.system.plymouth.logo = lib.mkOption {
      type = lib.types.path;
      default = ../../../assets/osa-logo-yellow.png;
      description = "Logo displayed by plymouth (PNG, 48x48 is GDM default but any size works). Yellow on transparent, 1/4 size for plymouth watermark.";
    };
  };

  nixos.ifEnabled = { cfg, ... }: {
    boot.plymouth.enable = true;
    boot.plymouth.theme = lib.mkDefault cfg.theme;
    # The theme is fixed and tested in its own repository. Keep one authoritative
    # `material` directory in the initrd, including for downstream hosts that
    # still add the old package explicitly.
    boot.plymouth.themePackages = lib.mkForce [
      cfg.pkg
    ];
    boot.plymouth.logo = lib.mkDefault cfg.logo;
    boot.plymouth.font = lib.mkDefault (
      cfg.pkg.font or "${pkgs.rubik}/share/fonts/truetype/Rubik-Regular.ttf"
    );

    # Keep the handoff to the shutdown splash visually clean.  Plymouth can
    # only take DRM ownership after the compositor has released it, so there
    # is a short VT interval during poweroff/reboot.  Make that interval truly
    # silent instead of letting systemd's `auto` status and kernel errors flash
    # on screen; diagnostics remain available in the journal.
    boot.consoleLogLevel = lib.mkDefault 0;
    boot.initrd.verbose = lib.mkDefault false;
    boot.kernelParams = lib.mkAfter [
      "quiet"
      "udev.log_level=3"
      "rd.udev.log_level=3"
      "systemd.show_status=false"
      "rd.systemd.show_status=false"
      "vt.global_cursor_default=0"
    ];

    # systemd-cryptsetup asks for the LUKS passphrase through Plymouth's
    # systemd password agent. The material theme implements DisplayPassword.
    boot.initrd.systemd.enable = lib.mkDefault true;
  };
}
