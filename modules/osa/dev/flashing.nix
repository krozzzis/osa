{ delib, lib, ... }:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.dev.flashing" (
      { pkgs }:
      delib.module {
        name = "osa.dev.flashing";
        options = { ... }: {
          osa.dev.flashing.enable = delib.boolOption true;
          # Flashing tools: probe-rs CLI and st-flash; channel defaults to nixpkgs-unstable.
          osa.dev.flashing.probeRsPkg = delib.packageOption pkgs.probe-rs-tools;
          osa.dev.flashing.stlinkPkg = delib.packageOption pkgs.stlink;
        };
        nixos.ifEnabled =
          {
            cfg,
            myconfig,
            ...
          }:
          {
            environment.systemPackages = [
              cfg.probeRsPkg
              cfg.stlinkPkg
            ];
            services.udev.packages = [
              cfg.stlinkPkg
              (pkgs.writeTextDir "lib/udev/rules.d/69-probe-rs.rules" ''
                # probe-rs / OpenOCD-style access for debug probes (ST-LINK, CMSIS-DAP, J-Link, Pico).
                # Based on upstream 69-probe-rs.rules (GPLv2).
                ACTION!="add|change", GOTO="probe_rs_rules_end"
                SUBSYSTEM=="gpio", MODE="0660", GROUP="plugdev", TAG+="uaccess"
                SUBSYSTEM!="usb|tty|hidraw", GOTO="probe_rs_rules_end"
                ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3744", MODE="660", GROUP="plugdev", TAG+="uaccess"
                ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3748", MODE="660", GROUP="plugdev", TAG+="uaccess"
                ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374b", MODE="660", GROUP="plugdev", TAG+="uaccess"
                ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374c", MODE="660", GROUP="plugdev", TAG+="uaccess"
                ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374d", MODE="660", GROUP="plugdev", TAG+="uaccess"
                ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374e", MODE="660", GROUP="plugdev", TAG+="uaccess"
                ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3752", MODE="660", GROUP="plugdev", TAG+="uaccess"
                ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3753", MODE="660", GROUP="plugdev", TAG+="uaccess"
                ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3754", MODE="660", GROUP="plugdev", TAG+="uaccess"
                ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3755", MODE="660", GROUP="plugdev", TAG+="uaccess"
                ATTRS{idVendor}=="0d28", ATTRS{idProduct}=="0204", MODE="660", GROUP="plugdev", TAG+="uaccess"
                ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="0003", MODE="660", GROUP="plugdev", TAG+="uaccess"
                ATTRS{idVendor}=="1366", ATTRS{idProduct}=="010[1-6]", MODE="660", GROUP="plugdev", TAG+="uaccess"
                ATTRS{idVendor}=="1366", ATTRS{idProduct}=="101[1-7]", MODE="660", GROUP="plugdev", TAG+="uaccess"
                ATTRS{idVendor}=="1366", ATTRS{idProduct}=="102[1-9]", MODE="660", GROUP="plugdev", TAG+="uaccess"
                ATTRS{idVendor}=="1915", ATTRS{idProduct}=="00[039a][012789ab]", MODE="660", GROUP="plugdev", TAG+="uaccess"
                LABEL="probe_rs_rules_end"
              '')
            ];
            # plugdev is referenced by the probe rules; uaccess grants the active
            # session user access, group membership covers non-seat sessions.
            users.groups.plugdev = lib.mkDefault { };
            users.users.${myconfig.user.constants.username}.extraGroups = [ "plugdev" ];
          };
      }
    ))
  ];
}
