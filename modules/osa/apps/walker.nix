{
  delib,
  pkgs,
  inputs,
  ...
}:
delib.module {
  name = "osa.apps.walker";

  options = { ... }: {
    osa.apps.walker.enable = delib.boolOption false;
    osa.apps.walker.pkg = delib.packageOption (
      inputs.walker.packages.${pkgs.stdenv.hostPlatform.system}.default or pkgs.walker
    );
  };

  nixos.always.nix.settings = {
    extra-substituters = [
      "https://walker.cachix.org"
      "https://walker-git.cachix.org"
    ];
    extra-trusted-public-keys = [
      "walker.cachix.org-1:fG8q+uAaMqhsMxWjwvk0IMb4mFPFLqHjuvfwQxE4oJM="
      "walker-git.cachix.org-1:vmC0ocfPWh0S/vRAQGtChuiZBTAe4wiKDeyyXM0/7pM="
    ];
  };

  home.always.imports = [ inputs.walker.homeManagerModules.default ];

  home.ifEnabled = { myconfig, ... }: {
    programs.walker = {
      enable = true;
      runAsService = true;
      # Переопределяем только font-family, сохраняя полный дефолтный стиль walker.
      # Без этого `themes.default.style` полностью перезаписывал бы
      # resources/themes/default/style.css (walker homeManager просто пишет файл),
      # оставляя тему без всех правил — отсюда "сломана" тема и неестественно большой шрифт.
      themes.default.style =
        let
          baseStyle = builtins.readFile "${inputs.walker}/resources/themes/default/style.css";
        in
        baseStyle
        + ''

          /* OSA override: системный шрифт из user.fonts.regular */
          * {
            font-family: "${myconfig.user.fonts.regular.name}", sans-serif;
          }
        '';
    };

    programs.elephant.enable = true;

    home.activation.restartElephant = ''
      rm -f "$HOME/.cache/walker/applications.json" 2>/dev/null || true
      systemctl --user try-restart elephant.service 2>/dev/null || true
      systemctl --user try-restart walker.service 2>/dev/null || true
    '';

    # systemd.user.services.elephant = {
    #   Unit = {
    #     Description = "Elephant";
    #     After = [ "graphical-session.target" ];
    #   };

    #   Service = {
    #     Type = "simple";
    #     ExecStart = "${pkgs.elephant}/bin/elephant";
    #     Restart = "on-failure";
    #   };

    #   Install = {
    #     WantedBy = [ "graphical-session.target" ];
    #   };
    # };
  };
}
