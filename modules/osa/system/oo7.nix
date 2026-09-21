{ delib, lib, ... }:
delib.module {
  name = "osa.system.oo7";

  options = { myconfig, ... }: {
    osa.system.oo7.enable = delib.boolOption myconfig.user.gui.enable;
  };

  nixos.ifEnabled = {
    # oo7 owns both Secret Service APIs: the traditional D-Bus API used by
    # libsecret/Electron/browsers and the portal API used by sandboxed apps.
    services.oo7.enable = true;
    services.gnome.gnome-keyring.enable = lib.mkForce false;

    xdg.portal.config = {
      common."org.freedesktop.impl.portal.Secret" = lib.mkForce [ "oo7-portal" ];

      # programs.niri provides its own desktop-specific portal configuration,
      # so the common fallback is not consulted for Niri sessions.
      niri."org.freedesktop.impl.portal.Secret" = lib.mkForce [ "oo7-portal" ];
    };

    # Let pam_oo7 start the daemon after it has captured the login password.
    # Eager startup can race PAM and leave the persistent keyring locked.
    systemd.user.services.oo7-daemon.wantedBy = lib.mkForce [ ];

    # oo7 replaces Secret Service, but deliberately is not an SSH agent.
    # Keep the capability previously supplied by gnome-keyring via OpenSSH's
    # dedicated agent and expose its socket to every graphical application.
    programs.ssh.startAgent = lib.mkDefault true;
    environment.sessionVariables.SSH_AUTH_SOCK = "\${XDG_RUNTIME_DIR}/ssh-agent";
  };
}
