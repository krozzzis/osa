{
  delib,
  lib,
  inputs,
  config,
  ...
}:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.apps.throne" (
      { pkgs }:
      let
        # Match the integration shipped alongside the selected application.
        coreNameFor =
          nixpkgs:
          if
            lib.hasInfix "/share/throne/ThroneCore" (
              builtins.readFile "${nixpkgs}/nixos/modules/programs/throne.nix"
            )
          then
            "ThroneCore"
          else
            "Core";
        wrapperNameFor = core: if core == "Core" then "throne-core" else core;
        hostWrapper = wrapperNameFor (coreNameFor inputs.nixpkgs);
      in
      delib.module {
        name = "osa.apps.throne";

        options = { myconfig, ... }: {
          osa.apps.throne = {
            enable = delib.boolOption myconfig.user.gui.enable;
            pkg = delib.packageOption pkgs.throne;
            coreName = lib.mkOption {
              type = lib.types.enum [
                "Core"
                "ThroneCore"
              ];
              default = coreNameFor pkgs.path;
              description = "Core executable name; override when using a custom Throne package with a different layout.";
            };
            tunMode = delib.description (delib.boolOption true) "Enable TUN mode for VPN";
          };
        };

        nixos.ifEnabled = { cfg, ... }: {
          programs.throne = {
            package = cfg.pkg;
            enable = true;
            tunMode.enable = cfg.tunMode;
          };
          security.wrappers = lib.mkIf cfg.tunMode (
            lib.optionalAttrs (hostWrapper != wrapperNameFor cfg.coreName) {
              ${hostWrapper}.enable = false;
            }
            // {
              ${wrapperNameFor cfg.coreName} = {
                source = lib.mkForce "${cfg.pkg}/share/throne/${cfg.coreName}";
                owner = "root";
                group = "root";
                setuid = config.programs.throne.tunMode.setuid;
                capabilities = lib.mkIf (
                  !config.programs.throne.tunMode.setuid
                ) "cap_net_admin,cap_net_raw,cap_net_bind_service,cap_sys_ptrace,cap_dac_read_search+ep";
              };
            }
          );
        };
      }
    ))
  ];
}
