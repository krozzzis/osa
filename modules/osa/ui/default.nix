{ delib, lib, ... }:
delib.module {
  name = "osa.ui";

  options = { myconfig, ... }: {
    osa.ui.transparency = lib.mkOption {
      type = lib.types.addCheck lib.types.float (value: value >= 0.0 && value <= 1.0);
      default = myconfig.user.ui.transparency;
      defaultText = lib.literalExpression "myconfig.user.ui.transparency";
      description = "Global UI transparency (0.0 fully transparent, 1.0 fully opaque) for all OSA apps. Defaults to user.ui.transparency (0.9 = 90%).";
    };

    osa.ui.cornerRadius = lib.mkOption {
      type = lib.types.ints.positive;
      default = myconfig.user.ui.cornerRadius;
      defaultText = lib.literalExpression "myconfig.user.ui.cornerRadius";
      description = "Global window corner radius (see user.ui.cornerRadius). Frame rounding is derived as cornerRadius + gap.";
    };

    osa.ui.gap = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = myconfig.user.ui.gap;
      defaultText = lib.literalExpression "myconfig.user.ui.gap";
      description = "Global compositor gap (see user.ui.gap). Used with cornerRadius to derive frameRounding.";
    };

    osa.ui.frameRounding = lib.mkOption {
      type = lib.types.ints.positive;
      default = myconfig.osa.ui.cornerRadius + myconfig.osa.ui.gap;
      defaultText = lib.literalExpression "myconfig.osa.ui.cornerRadius + myconfig.osa.ui.gap";
      description = "Frame (outer) corner radius derived as window cornerRadius + gap. Override only if you need an independent frame radius.";
    };
  };

  # Install shared fonts system-wide so applications use consistent fallbacks.
  nixos.always = { myconfig, ... }: {
    fonts.packages = [
      myconfig.user.fonts.regular.pkg
      myconfig.user.fonts.monospace.pkg
    ];
  };

  home.always =
    { myconfig, ... }:
    lib.mkIf myconfig.user.gui.enable {
      gtk = {
        enable = true;
        iconTheme = {
          package = myconfig.user.ui.iconTheme.pkg;
          name = myconfig.user.ui.iconTheme.name;
        };
      };
    };
}
