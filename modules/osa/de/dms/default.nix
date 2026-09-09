{
  delib,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  jsonFormat = pkgs.formats.json { };

  # DMS supports NixOS, but its doctor only checks ID=nixos and ignores
  # distributions (such as OSA) that advertise ID_LIKE=nixos.
  dmsPackage = (inputs.dms.lib.mkDmsShell pkgs).overrideAttrs (old: {
    # DMS stable aa4b99d changed its Go dependencies without updating the
    # fixed-output hash in the flake.
    vendorHash = "sha256-Ls6Dquwt0fzDCEjZ6FfTsZTXDI8408mFdByv/OWHVgI=";
    postPatch = (old.postPatch or "") + ''
      substituteInPlace cmd/dms/commands_doctor.go \
        --replace-fail \
          'case osRelease["ID"] == "nixos":' \
          'case osRelease["ID"] == "nixos" || strings.Contains(osRelease["ID_LIKE"], "nixos"):'
    '';
  });
in
delib.module {
  name = "osa.de.dms";

  options = {
    osa.de.dms = {
      enable = delib.boolOption false;
      pkg = delib.packageOption dmsPackage;
      quickshell.pkg =
        delib.packageOption
          inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
      settings = lib.mkOption {
        inherit (jsonFormat) type;
        default = { };
        description = "Declarative DMS settings merged into its writable runtime settings.json.";
      };
    };
  };

  home.always.imports = [
    inputs.dms.homeModules.dank-material-shell
    inputs.dms.homeModules.niri
    inputs.dms-plugin-registry.homeModules.default
  ];
}
