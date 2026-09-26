{
  delib,
  ...
}:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.apps.kdeconnect" (
      { pkgs }:
      delib.module {
        name = "osa.apps.kdeconnect";

        options = { myconfig, ... }: {
          osa.apps.kdeconnect.enable = delib.boolOption myconfig.user.gui.enable;
        };

        nixos.ifEnabled = {
          programs.kdeconnect.enable = true;
          programs.kdeconnect.package = pkgs.kdePackages.kdeconnect-kde;

          networking.firewall = {
            enable = true;
            allowedTCPPortRanges = [
              {
                from = 1714;
                to = 1764;
              }
            ];
            allowedUDPPortRanges = [
              {
                from = 1714;
                to = 1764;
              }
            ];
          };
        };
      }
    ))
  ];
}
