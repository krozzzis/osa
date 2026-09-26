{ delib, inputs, ... }:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.de.caelestia" (
      { pkgs }:
      delib.module {
        name = "osa.de.caelestia";

        options = delib.singleEnableOption false;

        home.always.imports = [ inputs.caelestia-shell.homeManagerModules.default ];

        # Hyprland-only (relies on Hyprland's dbus global-shortcuts protocol) --
        # pair with osa.de.hyprland, not niri.
        home.ifEnabled = {
          programs.caelestia = {
            enable = true;
            package = pkgs.callPackage "${inputs.caelestia-shell}/nix" {
              rev = inputs.caelestia-shell.rev or inputs.caelestia-shell.dirtyRev;
              stdenv = pkgs.clangStdenv;
              quickshell = (pkgs.extend inputs.quickshell.overlays.default).quickshell.override {
                withX11 = false;
                withI3 = false;
              };
              caelestia-cli =
                inputs.caelestia-shell.inputs.caelestia-cli.packages.${pkgs.stdenv.hostPlatform.system}.default;
              m3shapes =
                inputs.caelestia-shell.inputs.m3shapes.packages.${pkgs.stdenv.hostPlatform.system}.default;
            };
            cli.enable = true;
          };

          systemd.user.services.caelestia.Unit.ConditionEnvironment = "XDG_CURRENT_DESKTOP=Hyprland";
        };
      }
    ))
  ];
}
