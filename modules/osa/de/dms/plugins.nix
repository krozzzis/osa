{
  delib,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  dankCalendarSource =
    inputs.dms-plugin-registry.packages.${pkgs.stdenv.hostPlatform.system}.dankCalendar;
  dankCalendarPackage = pkgs.buildGoModule {
    pname = "dankcalendar";
    inherit (dankCalendarSource) version;
    src = dankCalendarSource;
    vendorHash = null;
    subPackages = [ "cmd/dankcalendar" ];
    ldflags = [
      "-s"
      "-w"
      "-X main.version=${dankCalendarSource.version}"
    ];
    meta = {
      description = "CalDAV CLI client for DankMaterialShell";
      homepage = "https://github.com/alcxyz/DankCalendar";
      license = lib.licenses.mit;
      mainProgram = "dankcalendar";
    };
  };
  dcalPackage = inputs.dankcalendar.lib.mkDcal pkgs;
in
delib.module {
  name = "osa.de.dms";

  home.ifEnabled = {
    home.packages = [
      # DMS's built-in calendar backend probes for dcal; the plugin below
      # provides the separate dankcalendar CLI.
      dcalPackage
      dankCalendarPackage
      pkgs.libnotify
      pkgs.libsecret
    ];

    systemd.user.services.dcal = {
      Unit = {
        Description = "Dank Calendar";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${lib.getExe dcalPackage} run --session --hidden";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    programs.dank-material-shell.plugins = {
      dankBatteryAlerts = {
        enable = true;
        # The registry also defines src at normal priority. Keep OSA's
        # newer pinned revision authoritative when importing that module.
        src = lib.mkForce (
          pkgs.fetchgit {
            url = "https://github.com/AvengeMedia/dms-plugins";
            rev = "3ad0e7845b62a9aca56f7959dd086b2a85655079";
            hash = "sha256-ygsn92Yt4e5YHutGnkTzb5rAuoiB5STYAQaORUjlqRk=";
          }
          + "/DankBatteryAlerts"
        );
      };
      dankCalendar.enable = true;
      volumeMixer.enable = true;
      dankKDEConnect.enable = true;
    };
  };
}
