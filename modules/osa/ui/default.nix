{
  delib,
  lib,
  pkgs,
  ...
}:
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

  # Install shared fonts and fallbacks system-wide.
  nixos.always = { myconfig, ... }: {
    fonts = {
      packages =
        (with pkgs; [
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-cjk-serif
          noto-fonts-color-emoji
          liberation_ttf
          twemoji-color-font
          myconfig.user.fonts.regular.pkg
          myconfig.user.fonts.monospace.pkg
        ])
        ++ lib.optionals myconfig.user.gui.fonts.nerdfonts (
          with pkgs;
          [
            nerd-fonts.fira-code
            nerd-fonts.jetbrains-mono
            nerd-fonts.symbols-only
          ]
        );

      fontconfig.defaultFonts = {
        serif = [
          "Noto Serif"
          "Noto Serif CJK SC"
        ];
        sansSerif = [
          myconfig.user.fonts.regular.name
          "Noto Sans CJK SC"
        ];
        monospace = [
          (
            if myconfig.user.gui.fonts.nerdfonts then
              "JetBrainsMono Nerd Font"
            else
              myconfig.user.fonts.monospace.name
          )
          "Noto Sans Mono CJK SC"
        ];
        emoji = [
          "Twemoji Mozilla"
          "Noto Color Emoji"
        ];
      };
    };
  };

  home.always =
    { myconfig, ... }:
    lib.mkIf myconfig.user.gui.enable {
      gtk = {
        enable = true;
        font = {
          name = myconfig.user.fonts.regular.name;
          size = myconfig.user.ui.fontSize;
        };
        iconTheme = {
          package = myconfig.user.ui.iconTheme.pkg;
          name = myconfig.user.ui.iconTheme.name;
        };
      };

      qt = {
        enable = true;
        platformTheme.name = "qtct";
      };

      # Niri uses the KDE platform theme for Qt applications.
      xdg.configFile."kdeglobals".text =
        let
          size = toString myconfig.user.ui.fontSize;
          font = "${myconfig.user.fonts.regular.name},${size},-1,5,50,0,0,0,0,0";
          fixedFont = "${myconfig.user.fonts.monospace.name},${size},-1,5,50,0,0,0,0,0";
        in
        ''
          [General]
          fixed=${fixedFont}
          font=${font}
          menuFont=${font}
          smallestReadableFont=${font}
          toolBarFont=${font}

          [WM]
          activeFont=${font}
        '';

      home.packages = [
        myconfig.user.fonts.regular.pkg
        myconfig.user.fonts.monospace.pkg
      ];
    };
}
