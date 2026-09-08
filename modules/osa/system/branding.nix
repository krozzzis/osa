{
  delib,
  lib,
  ...
}:
delib.module {
  name = "osa.system.branding";

  options = {
    osa.system.branding = {
      distroName = delib.description (delib.strOption "OSA") "Human-readable OS name (NAME/PRETTY_NAME in /etc/os-release, DISTRIB_DESCRIPTION in /etc/lsb-release).";
      distroId = delib.description (delib.strOption "osa") "Lower-case OS id (ID in /etc/os-release, DISTRIB_ID in /etc/lsb-release). Anything other than \"nixos\" automatically gets ID_LIKE=nixos added by NixOS itself, which is what keeps distro-detection scripts treating this as NixOS-compatible.";
      vendorName = delib.description (delib.strOption "OSA") "Vendor name (VENDOR_NAME in /etc/os-release, part of CPE_NAME).";
      vendorId = delib.description (delib.strOption "osa") "Vendor id (part of CPE_NAME).";

      tagline = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Human-readable variant description (VARIANT in /etc/os-release).";
      };
      variantId = lib.mkOption {
        type = lib.types.nullOr (lib.types.strMatching "^[a-z0-9._-]+$");
        default = null;
        description = "Lower-case variant id (VARIANT_ID in /etc/os-release).";
      };

      ansiColor = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''ANSI_COLOR for /etc/os-release, e.g. "0;38;2;126;186;228".'';
      };

      homeUrl = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "HOME_URL for /etc/os-release.";
      };
      supportUrl = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "SUPPORT_URL for /etc/os-release.";
      };
      bugReportUrl = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "BUG_REPORT_URL for /etc/os-release.";
      };
    };
  };

  nixos.always =
    { myconfig, ... }:
    let
      cfg = myconfig.osa.system.branding;
    in
    {
      system.nixos.distroName = cfg.distroName;
      system.nixos.distroId = cfg.distroId;
      system.nixos.vendorName = cfg.vendorName;
      system.nixos.vendorId = cfg.vendorId;
      system.nixos.variantName = cfg.tagline;
      system.nixos.variant_id = cfg.variantId;

      # HOME_URL/SUPPORT_URL/BUG_REPORT_URL/ANSI_COLOR are only emitted by
      # NixOS' own os-release generator when distroId == "nixos", so with a
      # custom distroId they have to be re-added here to not just vanish.
      system.nixos.extraOSReleaseArgs = lib.filterAttrs (_: v: v != null) {
        ANSI_COLOR = cfg.ansiColor;
        HOME_URL = cfg.homeUrl;
        SUPPORT_URL = cfg.supportUrl;
        BUG_REPORT_URL = cfg.bugReportUrl;
      };

      # /etc/os-release automatically gets ID_LIKE=nixos added by NixOS
      # itself when distroId != "nixos" (see the distroId description
      # above), but the same generator has no equivalent for
      # /etc/lsb-release, so it has to be added by hand here to keep
      # distro-detection scripts that only check lsb-release working too.
      system.nixos.extraLSBReleaseArgs = lib.optionalAttrs (cfg.distroId != "nixos") {
        DISTRIB_ID_LIKE = "nixos";
      };

      environment.etc."issue".text = "${cfg.distroName} \\n \\l\n\n";
    };
}
