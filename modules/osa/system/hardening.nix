{ delib, lib, pkgs, ... }:

delib.module {
  name = "osa.system.hardening";

  options = delib.singleEnableOption true;

  nixos.ifEnabled = {
    security.pki.caCertificateBlacklist = [
      "Comodo AAA Services root"
    ] ++ lib.optionals (lib.versionOlder (lib.getVersion pkgs.cacert) "3.131.1") [
      # NSS 3.131.1 removed these roots entirely; buildcatrust rejects names
      # absent from its certificate store. Older releases still need the block.
      "emSign ECC Root CA - G3"
      "emSign Root CA - C1"
      "emSign ECC Root CA - C3"
    ];
  };
}
