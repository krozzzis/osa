{
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.system.autoClean";

  options = { ... }: {
    osa.system.autoClean.enable = delib.boolOption true;
    osa.system.autoClean.keepGenerations = lib.mkOption {
      type = lib.types.ints.positive;
      default = 4;
      description = "Number of system and Home Manager generations to retain.";
    };
  };

  nixos.ifEnabled = { cfg, ... }: {
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    nix.settings.auto-optimise-store = true;

    systemd.services.nix-generation-prune = {
      description = "Prune old NixOS generations";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "nix-auto-clean" ''
          set -euo pipefail

          ${pkgs.nix}/bin/nix-env \
            --profile /nix/var/nix/profiles/system \
            --delete-generations +${toString cfg.keepGenerations}
        ''}";
        Nice = 19;
      };
    };

    systemd.timers.nix-generation-prune = {
      description = "Weekly NixOS generation pruning";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
      };
    };
  };

  home.ifEnabled = { cfg, ... }: {
    systemd.user.services.home-manager-generation-prune = {
      Unit.Description = "Prune old Home Manager generations";
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.home-manager}/bin/home-manager expire-generations '-${toString cfg.keepGenerations} generations'";
      };
    };

    systemd.user.timers.home-manager-generation-prune = {
      Unit.Description = "Weekly Home Manager generation pruning";
      Timer = {
        OnCalendar = "weekly";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
