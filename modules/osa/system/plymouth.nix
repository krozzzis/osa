{
  delib,
  inputs,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.system.plymouth";

  options = { ... }: {
    osa.system.plymouth.enable = delib.boolOption false;
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

  nixos.ifEnabled = { cfg, myconfig, ... }: {
    boot.plymouth.enable = true;
    boot.plymouth.theme = lib.mkDefault cfg.theme;
    # The theme is fixed and tested in its own repository. Keep one authoritative
    # `material` directory in the initrd, including for downstream hosts that
    # still add the old package explicitly.
    boot.plymouth.themePackages = lib.mkForce [
      inputs.plymouth-theme-material.packages.${pkgs.stdenv.hostPlatform.system}.plymouth-theme-material
    ];
    boot.plymouth.logo = lib.mkDefault cfg.logo;
    boot.plymouth.font = lib.mkDefault "${myconfig.user.fonts.regular.pkg}/share/fonts/truetype/InterVariable.ttf";

    # systemd-cryptsetup asks for the LUKS passphrase through Plymouth's
    # systemd password agent. The material theme implements DisplayPassword.
    boot.initrd.systemd.enable = lib.mkDefault true;
  };
}
