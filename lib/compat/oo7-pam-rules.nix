{ lib, ... }:
{
  options.security.pam.services = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }: {
          config = lib.mkIf (config.oo7.enable && (config.useDefaultRules or true)) {
            # pam_unix's sufficient success would skip keyring password updates.
            # A failed system password update must stop before changing the keyring.
            rules.password.unix.control = lib.mkForce "requisite";
            rules.password.oo7.order = lib.mkForce (config.rules.password.unix.order + 1);
          };
        }
      )
    );
  };
}
