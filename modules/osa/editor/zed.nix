{
  delib,
  ...
}:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.editor.zed" (
      { pkgs }:
      delib.module {
        name = "osa.editor.zed";

        options = { myconfig, ... }: {
          osa.editor.zed.enable = delib.boolOption myconfig.user.gui.enable;
          osa.editor.zed.desktop = delib.strOption "dev.zed.Zed.desktop";
          osa.editor.zed.pkg = delib.packageOption pkgs.zed-editor;
        };

        nixos.ifEnabled.programs.nix-ld.enable = true;

        home.ifEnabled =
          { cfg, ... }:
          {
            home.packages = with pkgs; [
              nixfmt
            ];

            programs.zed-editor = {
              enable = true;
              package = cfg.pkg;

              extensions = [
                "nix"
                "rust"
                "toml"
              ];

              extraPackages = [
                pkgs.nixfmt
              ];

              userSettings = {
                telemetry = {
                  diagnostics = false;
                  metrics = false;
                };

                title_bar = {
                  show_sign_in = false;
                  show_branch_icon = false;
                };

                auto_install_extensions.html = true;

                languages = {
                  Nix = {
                    formatter.external = {
                      command = "nixfmt";
                    };
                  };
                };
              };
            };
          };
      }
    ))
  ];
}
