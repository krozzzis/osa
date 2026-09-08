{
  delib,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  upstreamTheme = inputs.plymouth-theme-material.packages.${system}.plymouth-theme-material;
  materialTheme = pkgs.runCommand "osa-plymouth-theme-material" { } ''
    theme_dir="$out/share/plymouth/themes/material"
    mkdir -p "$theme_dir"
    cp -r ${upstreamTheme}/share/plymouth/themes/material/. "$theme_dir/"
    chmod -R u+w "$theme_dir"

    substituteInPlace "$theme_dir/material.plymouth" \
      --replace-fail '${upstreamTheme}/share/plymouth/themes/material' "$theme_dir"

    # Plymouth Script has no C-style ternary operator. Version 1.4 of the
    # upstream OSA theme used it in four opacity expressions, which made the
    # script plugin reject the whole theme and left only the firmware logo.
    substituteInPlace "$theme_dir/material.script" \
      --replace-fail '(global.capslock_active ? 1 : 0)' 'global.capslock_active' \
      --replace-fail '(dialog.bullet[index].should_show ? 1 : 0)' 'dialog.bullet[index].should_show' \
      --replace-fail 'SetOpacity(capslock ? 1 : 0);' 'SetOpacity(capslock);'

    if grep -Eq '\?.*:|SetOpacity[A-Za-z_]' "$theme_dir/material.script"; then
      echo "invalid syntax remains in material.script" >&2
      exit 1
    fi
  '';
in
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
    # A downstream configuration can still carry the old upstream package.
    # Force the patched package so its identically named `material` directory
    # cannot shadow this one in the initrd.
    boot.plymouth.themePackages = lib.mkForce [ materialTheme ];
    boot.plymouth.logo = lib.mkDefault cfg.logo;
    boot.plymouth.font = lib.mkDefault "${myconfig.user.fonts.regular.pkg}/share/fonts/truetype/InterVariable.ttf";

    # systemd-cryptsetup asks for the LUKS passphrase through Plymouth's
    # systemd password agent. The material theme implements DisplayPassword.
    boot.initrd.systemd.enable = lib.mkDefault true;
  };
}
