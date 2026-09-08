{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.system.autoClean";

  options = { ... }: {
    osa.system.autoClean.enable = delib.boolOption true;
    osa.system.autoClean.keepGenerations = delib.description (delib.intOption 4) "Number of system/home-manager generations to keep";
  };

  nixos.ifEnabled = { cfg, ... }: {
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    nix.settings.auto-optimise-store = true;

    systemd.services.nix-auto-clean = {
      description = "Delete old NixOS and home-manager generations";
      after = [ "network.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "nix-auto-clean" ''
          set -euo pipefail

          KEEP=${toString cfg.keepGenerations}

          # Delete old system generations
          ${pkgs.nix}/bin/nix-env -p /nix/var/nix/profiles/system --delete-generations +$KEEP 2>/dev/null || true

          # Delete old home-manager generations
          if command -v home-manager >/dev/null; then
            GEN_LIST=$(home-manager generations 2>/dev/null | ${pkgs.gnugrep}/bin/grep -Eo '^[0-9]+' | sort -n | head -n -$KEEP || true)
            if [ -n "$GEN_LIST" ]; then
              echo "$GEN_LIST" | xargs -r home-manager remove-generations 2>/dev/null || true
            fi
          fi

          # Garbage collection
          ${pkgs.nix}/bin/nix-collect-garbage --delete-older-than 14d 2>/dev/null || true
        ''}";
        Nice = 19;
      };
    };

    systemd.timers.nix-auto-clean = {
      description = "Weekly Nix cleanup";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
      };
    };
  };
}
