{
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.system.hibernate";

  options = { ... }: {
    osa.system.hibernate.enable = delib.boolOption false;

    osa.system.hibernate.delay = lib.mkOption {
      type = lib.types.str;
      default = "30min";
      description = "How long to stay in s2idle before RTC wakes the machine and hibernates (systemd HibernateDelaySec).";
    };

    osa.system.hibernate.suspendEstimationSec = lib.mkOption {
      type = lib.types.str;
      default = "30min";
      description = "Estimation window for battery discharge (systemd SuspendEstimationSec). Keep in sync with delay for deterministic behaviour.";
    };

    osa.system.hibernate.hibernateOnACPower = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to hibernate even when on AC power (systemd HibernateOnACPower).";
    };

    osa.system.hibernate.resumeDevice = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Resume device for hibernation (boot.resumeDevice, e.g. /dev/mapper/cryptroot). Host-specific.";
    };

    osa.system.hibernate.resumeOffset = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "Resume offset inside the swapfile (boot.kernelParams resume_offset). Host-specific, from btrfs inspect-internal map-swapfile -r /swap/swapfile.";
    };
  };

  nixos.ifEnabled = { cfg, ... }: {
    # Generic power plumbing for suspend-then-hibernate
    powerManagement.enable = true;
    services.power-profiles-daemon.enable = true;

    services.journald.settings.Journal.SyncIntervalSec = "5s";

    # s2idle on this hardware needs PSR disabled or resume freezes
    boot.kernelParams = lib.optionals (cfg.resumeOffset != null) [
      "resume_offset=${toString cfg.resumeOffset}"
    ];

    boot.resumeDevice = lib.mkIf (cfg.resumeDevice != null) cfg.resumeDevice;

    # DMS greeter can freeze after s2idle resume
    systemd.services.greetd-resume-recover = {
      description = "Restart the greetd greeter if it is frozen after resume";
      wantedBy = [ "post-resume.target" ];
      after = [ "post-resume.target" ];
      serviceConfig.Type = "oneshot";
      script = ''
        if ! loginctl list-sessions --no-legend 2>/dev/null \
             | awk '{ print $3 }' \
             | grep -vE '^(dms-greeter|greeter|-|root)$' \
             | grep -q .; then
          systemctl restart greetd
        fi
      '';
    };

    services.logind.settings.Login = {
      HandleLidSwitch = "suspend-then-hibernate";
      HandleLidSwitchExternalPower = "suspend-then-hibernate";
      HandleSuspendKey = "suspend-then-hibernate";
    };

    systemd.sleep.settings.Sleep = {
      HibernateDelaySec = cfg.delay;
      SuspendEstimationSec = cfg.suspendEstimationSec;
      HibernateOnACPower = cfg.hibernateOnACPower;
    };

    # systemd uses an alarmtimer for suspend-then-hibernate.  Some AMD s2idle
    # firmware (notably Renoir/Lucienne/Cezanne) does not turn that alarm into
    # a platform wake event: opening the lid later wakes the machine, at which
    # point systemd notices the expired timer and hibernates immediately.
    # Program the RTC's legacy wakealarm as well so the firmware actually wakes
    # the machine at HibernateDelaySec.  systemd still owns the decision to
    # hibernate; this hook only supplies the missing hardware wake event.
    environment.etc."systemd/system-sleep/osa-suspend-then-hibernate-rtc".source =
      pkgs.writeShellScript "osa-suspend-then-hibernate-rtc" ''
        set -eu

        wakealarm=/sys/class/rtc/rtc0/wakealarm
        if [ "$2" != suspend-then-hibernate ] || [ ! -w "$wakealarm" ]; then
          exit 0
        fi

        case "$1:''${SYSTEMD_SLEEP_ACTION:-}" in
          pre:suspend)
            delay_usec="$(${pkgs.systemd}/bin/systemd-analyze timespan ${lib.escapeShellArg cfg.delay} \
              | ${pkgs.gnused}/bin/sed -n 's/^[[:space:]]*μs:[[:space:]]*//p')"
            if [ -z "$delay_usec" ]; then
              echo "Could not parse HibernateDelaySec=${cfg.delay}" >&2
              exit 1
            fi

            now="$(${pkgs.coreutils}/bin/cat /sys/class/rtc/rtc0/since_epoch)"
            echo 0 > "$wakealarm"
            echo "$((now + delay_usec / 1000000))" > "$wakealarm"
            ;;
          post:suspend)
            # Avoid leaving a stale alarm behind after a manual wakeup.
            echo 0 > "$wakealarm"
            ;;
        esac
      '';
  };
}
