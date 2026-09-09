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
in
delib.module {
  name = "osa.de.dms";

  home.ifEnabled = {
    home.packages = [
      dankCalendarPackage
      pkgs.libnotify
      pkgs.libsecret
    ];

    programs.dank-material-shell.plugins = {
      dankBatteryAlerts.enable = true;
      dankCalendar.enable = true;
      volumeMixer.enable = true;
      dankKDEConnect.enable = true;
    };
  };
}
