{ delib, inputs, ... }:
delib.module {
  name = "osa.de.caelestia";

  options = delib.singleEnableOption false;

  home.always.imports = [ inputs.caelestia-shell.homeManagerModules.default ];

  # Hyprland-only (relies on Hyprland's dbus global-shortcuts protocol) --
  # pair with osa.de.hyprland, not niri.
  home.ifEnabled = {
    programs.caelestia = {
      enable = true;
      cli.enable = true;
    };

    systemd.user.services.caelestia.Unit.ConditionEnvironment = "XDG_CURRENT_DESKTOP=Hyprland";
  };
}
