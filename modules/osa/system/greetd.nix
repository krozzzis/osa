{ delib, pkgs, ... }:
delib.module {
  name = "osa.system.greetd";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    services.greetd = {
      enable = true;
      # settings = {
      #   default_session = {
      #     command = "${pkgs.dbus}/bin/dbus-run-session /${pkgs.cage}/bin/cage /${pkgs.cosmic-greeter}/bin/cosmic-greeter >>/var/log/cosmic.log 2>&1";
      #     user = "cosmic-greeter";
      #   };
      # };
    };

    environment.systemPackages = with pkgs; [
      cage
      cosmic-greeter
    ];
  };
}
