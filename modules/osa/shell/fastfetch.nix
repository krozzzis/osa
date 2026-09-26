{ delib, ... }:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.shell.fastfetch" (
      { pkgs }:
      delib.module {
        name = "osa.shell.fastfetch";

        options = { myconfig, ... }: {
          osa.shell.fastfetch.enable = delib.boolOption myconfig.user.shell.enable;
        };

        home.ifEnabled = {
          programs.fastfetch = {
            package = pkgs.fastfetch;
            enable = true;
            # NB: a fastfetch config file *replaces* the built-in default structure
            # entirely -- a config that only sets `logo` (no `modules`) renders the
            # logo and nothing else. So spell out the standard default layout here.
            settings = {
              logo = {
                # Plain-text ASCII rendition of the OSA wasp logo
                # (assets/osa-logo.png, traced once into assets/osa-logo.txt).
                # Lines carry $1 placeholders so the wasp comes out wasp-colored.
                type = "file";
                source = ../../../assets/osa-logo.txt;
                color."1" = "yellow";
                padding.top = 2;
              };

              modules = [
                "break"
                "title"
                "separator"
                "os"
                "host"
                "kernel"
                "uptime"
                "packages"
                "shell"
                "display"
                "de"
                "wm"
                "wmtheme"
                "theme"
                "icons"
                "font"
                "cursor"
                "terminal"
                "terminalfont"
                "cpu"
                "gpu"
                "memory"
                "swap"
                "disk"
                "battery"
                "poweradapter"
                "localip"
                "locale"
                "break"
                "colors"
              ];
            };
          };
        };
      }
    ))
  ];
}
