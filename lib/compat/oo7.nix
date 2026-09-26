# NixOS 26.05 has oo7 0.6 but not its NixOS/PAM integration yet.
# Compile the PAM library with the host's stdenv: loading an unstable-glibc
# PAM module into a stable login process is not ABI safe.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  oo7Pkgs = pkgs.extend (
    _: prev: {
      oo7-pam = prev.callPackage "${inputs.nixpkgs-unstable}/pkgs/by-name/oo/oo7-pam/package.nix" { };
    }
  );
in
{
  imports = [
    (import "${inputs.nixpkgs-unstable}/nixos/modules/services/desktops/oo7.nix" {
      inherit config lib;
      pkgs = oo7Pkgs;
    })
  ];
  options.security.pam.services = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }: {
          options.oo7.enable = lib.mkEnableOption "unlocking the oo7 keyring through PAM";
          config = lib.mkIf config.oo7.enable {
            rules = {
              # pam_unix's sufficient success otherwise skips the optional oo7
              # rule. Capture PAM_AUTHTOK first, as upstream pam.nix does.
              auth.osa-oo7-unix = {
                enable = config.unixAuth;
                order = config.rules.auth.unix.order - 2;
                control = "optional";
                modulePath = "${pkgs.pam}/lib/security/pam_unix.so";
                settings = {
                  nullok = config.allowNullPassword;
                  inherit (config) nodelay;
                  likeauth = true;
                  try_first_pass = true;
                };
              };
              auth.oo7 = {
                order = config.rules.auth.unix.order - 1;
                control = "optional";
                modulePath = "${oo7Pkgs.oo7-pam}/lib/security/pam_oo7.so";
              };
              password.oo7 = {
                order = config.rules.password.gnome_keyring.order + 1;
                control = "optional";
                modulePath = "${oo7Pkgs.oo7-pam}/lib/security/pam_oo7.so";
              };
              session.oo7 = {
                order = config.rules.session.gnome_keyring.order + 1;
                control = "optional";
                modulePath = "${oo7Pkgs.oo7-pam}/lib/security/pam_oo7.so";
                settings.auto_start = true;
              };
            };
          };
        }
      )
    );
  };
}
