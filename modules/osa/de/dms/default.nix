{
  delib,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ((import ../../../../lib/package-module.nix) "osa.de.dms" (
      { pkgs }:
      let
        jsonFormat = pkgs.formats.json { };

        # DMS supports NixOS, but its doctor only checks ID=nixos and ignores
        # distributions (such as OSA) that advertise ID_LIKE=nixos.
        dmsPackage = (inputs.dms.lib.mkDmsShell pkgs).overrideAttrs (
          old:
          {
            postPatch = (old.postPatch or "") + ''
              substituteInPlace cmd/dms/commands_doctor.go \
                --replace-fail \
                  'case osRelease["ID"] == "nixos":' \
                  'case osRelease["ID"] == "nixos" || strings.Contains(osRelease["ID_LIKE"], "nixos"):'
            '';
            postInstall = (old.postInstall or "") + ''
                # A light DMS mode must be an explicit portal preference. A
                # stale dark GTK theme otherwise wins over "no preference".
                substituteInPlace "$out/share/quickshell/dms/Services/PortalService.qml" \
                  --replace-fail \
                    'const targetScheme = isLightMode ? (preferLight ? "prefer-light" : "default") : "prefer-dark";' \
                    'const targetScheme = isLightMode ? "prefer-light" : "prefer-dark";' \
                  --replace-fail \
                    'Quickshell.execDetached(["sh", "-c", GSettings.setCmd("org.gnome.desktop.interface", "color-scheme", targetScheme)]);' \
                    'const schema = "org.gnome.desktop.interface";
              const currentGtk = GSettings.getCmd(schema, "gtk-theme");
              const adwTheme = isLightMode ? "adw-gtk3" : "adw-gtk3-dark";
              const defaultTheme = isLightMode ? "Adwaita" : "Adwaita-dark";
              const syncGtk = "current=$(" + currentGtk + "); case \"$current\" in adw-gtk3|adw-gtk3-dark) " + GSettings.setCmd(schema, "gtk-theme", adwTheme) + " ;; Adwaita|Adwaita-dark) " + GSettings.setCmd(schema, "gtk-theme", defaultTheme) + " ;; esac";
              Quickshell.execDetached(["sh", "-c", GSettings.setCmd(schema, "color-scheme", targetScheme) + "; " + syncGtk]);' \
                  --replace-fail \
                    'Component.onCompleted: {' \
                    'Component.onCompleted: {
              if (typeof SettingsData !== "undefined" && SettingsData.syncModeWithPortal && typeof Theme !== "undefined")
                  Qt.callLater(() => root.setSystemColorScheme(Theme.isLightMode));'

                if [ -f "$out/share/quickshell/dms/Widgets/WorkspaceSwitcherModel.qml" ]; then
                  substituteInPlace $out/share/quickshell/dms/Common/SettingsData.qml \
                    --replace-fail \
                      'property var workspaceNameIcons: Spec.SPEC.workspaceNameIcons.def' \
                      'property var workspaceNameIcons: Spec.SPEC.workspaceNameIcons.def
                property var workspaceNames: Spec.SPEC.workspaceNames.def'
                  substituteInPlace $out/share/quickshell/dms/Common/settings/SettingsSpec.js \
                    --replace-fail \
                      'workspaceNameIcons: {' \
                      'workspaceNames: { def: [] },
              workspaceNameIcons: {'
                  substituteInPlace $out/share/quickshell/dms/Widgets/WorkspaceSwitcherModel.qml \
                    --replace-fail \
                      'const baseList = CompositorService.workspacesForScreen' \
                      'let baseList = CompositorService.workspacesForScreen' \
                    --replace-fail \
                      'if (CompositorService.ephemeralWorkspaces)' \
                      'if (CompositorService.isNiri && SettingsData.workspaceNames.length > 0) {
                        const order = new Map(SettingsData.workspaceNames.map((name, index) => [name, index]));
                        baseList = baseList.filter(ws => order.has(ws.name));
                        baseList.sort((a, b) => order.get(a.name) - order.get(b.name));
                    }
                    if (CompositorService.ephemeralWorkspaces)'
                  polkitMessageProperty=supportingText
                else
                  substituteInPlace $out/share/quickshell/dms/Common/SettingsData.qml \
                    --replace-fail \
                      'property var workspaceNameIcons: ({})' \
                      'property var workspaceNameIcons: ({})
                property var workspaceNames: []'
                  substituteInPlace $out/share/quickshell/dms/Common/settings/SettingsSpec.js \
                    --replace-fail \
                      'workspaceNameIcons: { def: {} },' \
                      'workspaceNameIcons: { def: {} },
              workspaceNames: { def: [] },'
                  substituteInPlace $out/share/quickshell/dms/Modules/DankBar/Widgets/WorkspaceSwitcher.qml \
                    --replace-fail \
                      'workspaces = workspaces.slice().sort((a, b) => a.idx - b.idx);' \
                      'workspaces = workspaces.slice().sort((a, b) => a.idx - b.idx);

                    if (SettingsData.workspaceNames.length > 0) {
                        const order = new Map(SettingsData.workspaceNames.map((name, index) => [name, index]));
                        workspaces = workspaces.filter(ws => order.has(ws.name));
                        workspaces.sort((a, b) => order.get(a.name) - order.get(b.name));
                    }'
                  polkitMessageProperty=text
                fi
                  # Polkit messages often contain the executable path.  A Nix store
                  # hash is useful for reproducibility but is not a useful identity
                  # in an authentication dialog, so retain the package name instead.
                  substituteInPlace $out/share/quickshell/dms/Modals/PolkitAuthContent.qml \
                    --replace-fail \
                      "$polkitMessageProperty: root.currentFlow?.message ?? \"\"" \
                      "$polkitMessageProperty:"' (root.currentFlow?.message ?? "").replace(
                        /\/nix\/store\/[0-9a-z]{32}-([^\/\s]+)(?:\/[^\s]*)?/g,
                        (_, packageName) => {
                            const name = packageName.replace(/-[0-9][0-9A-Za-z.+-]*$/, "");
                            return ({
                                "gparted": "GParted",
                                "nixos-rebuild": "NixOS Rebuild",
                                "osa": "OSA"
                            })[name] ?? name;
                        }
                      )'
            '';
          }
          // lib.optionalAttrs ((inputs.dms.rev or "") == "aa4b99def48637d86a69620c0a8f3cc6aa0c4092") {
            # Only this older release needs its upstream vendor hash corrected.
            vendorHash = "sha256-ejDi+TzstUtxtWpcl5yYw4UZuTnZraOsIdJuXPKxJ6s=";
          }
        );
      in
      delib.module {
        name = "osa.de.dms";

        options = { cfg, myconfig, ... }: {
          osa.de.dms = {
            enable = delib.boolOption false;
            pkg = delib.packageOption dmsPackage;
            quickshell.nixpkgs = lib.mkOption {
              type = lib.types.enum (
                builtins.attrNames (import ../../../../lib/nixpkgs-sources.nix { inherit inputs; })
              );
              default = cfg.nixpkgs;
              description = "Channel for the cached Quickshell release package; follows DMS to keep Qt compatible.";
            };
            quickshell.pkg =
              delib.packageOption
                myconfig.osa.nixpkgs.packages.${cfg.quickshell.nixpkgs}.quickshell;
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
    ))
  ];
}
