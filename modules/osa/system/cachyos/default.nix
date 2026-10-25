{
  delib,
  inputs,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.system.cachyos";

  options = { ... }: {
    osa.system.cachyos = {
      enable = delib.boolOption false;
      variant = lib.mkOption {
        type = lib.types.enum [
          "lto"
          "lto-znver4"
          "bore"
          "eevdf"
          "lts"
        ];
        default = "lto";
        description = "Unmodified, cacheable Nyx CachyOS variant. lto-znver4 requires Zen 4 or newer; use lto on older CPUs.";
      };
    };
  };

  nixos.ifEnabled = { cfg, ... }: {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
        message = "osa.system.cachyos requires an x86_64-linux host.";
      }
    ];

    # Select upstream's package set directly, without host overlays, config
    # overrides or kernel recompilation. External modules follow this kernel.
    boot.kernelPackages =
      inputs.chaotic.legacyPackages.${pkgs.stdenv.hostPlatform.system}."linuxPackages_cachyos-${cfg.variant}";

    # Consume the pinned upstream URLs and signing keys; a dependency's
    # nixConfig alone does not configure the host's Nix daemon.
    nix.settings = {
      substituters = inputs.chaotic.nixConfig.extra-substituters;
      trusted-public-keys = inputs.chaotic.nixConfig.extra-trusted-public-keys;
    };
  };
}
