{
  delib,
  lib,
  inputs,
  ...
}:
delib.module {
  name = "osa.system.oo7";

  options = { myconfig, ... }: {
    osa.system.oo7.enable = delib.boolOption myconfig.user.gui.enable;
  };

  nixos.always.imports = [
    ../../../lib/compat/oo7-pam-rules.nix
  ]
  ++ lib.optionals (inputs.nixpkgs.lib.versionOlder inputs.nixpkgs.lib.version "26.11") [
    ../../../lib/compat/oo7.nix
  ];

  nixos.ifEnabled = {
    nixpkgs.overlays = [
      (_: prev: {
        oo7-pam = import ../../../lib/compat/oo7-pam.nix {
          pkgs = prev;
          inherit inputs;
        };
      })
    ];

    # Password changes must update the keyring too. Lockers that use login or
    # swaylock only authenticate, without opening another PAM session.
    security.pam.services.login = {
      oo7.enable = true;
      rules.auth.oo7.settings.unlock = true;
    };
    security.pam.services.passwd.oo7.enable = true;
    security.pam.services.swaylock = {
      oo7.enable = true;
      rules.auth.oo7.settings.unlock = true;
    };

    # greetd authenticates DMS sessions. Stable NixOS has its own PAM stack;
    # newer NixOS includes login's stack, which already enables oo7.
    security.pam.services.greetd.oo7.enable = true;

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
