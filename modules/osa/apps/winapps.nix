{
  delib,
  inputs,
  lib,
  ...
}:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.apps.winapps" (
      { pkgs }:
      let
        winapps =
          (pkgs.callPackage "${inputs.winapps}/packages/winapps" {
            inherit (inputs.winapps.inputs) nix-filter;
          }).overrideAttrs
            (old: {
              postPatch = (old.postPatch or "") + ''
                substituteInPlace bin/winapps \
                  --replace-fail 'docker compose --file "$COMPOSE_PATH" pause &>/dev/null' \
                    'docker compose --file "$COMPOSE_PATH" stop &>/dev/null'
                substituteInPlace bin/winapps \
                  --replace-fail 'Pausing Windows due to inactivity.' \
                    'Stopping Windows due to inactivity.'
              '';
            });
        winappsExe = winappsPkg: pkgs.writeShellScriptBin "winapps-exe" ''
          set -euo pipefail

          if [ "$#" -ne 1 ]; then
            echo "Usage: winapps-exe /path/to/application.exe" >&2
            exit 2
          fi

          shared="$HOME/Documents/VMShared"
          executable="$(${pkgs.coreutils}/bin/realpath -- "$1")"
          case "$executable" in
            "$shared"/*) relative="''${executable#"$shared"/}" ;;
            *) echo "The executable must be in $shared" >&2; exit 2 ;;
          esac
          if [ ! -f "$executable" ]; then
            echo "Executable not found: $executable" >&2
            exit 2
          fi

          compose="$HOME/.config/winapps/compose.yaml"
          if ! docker container inspect WinApps >/dev/null 2>&1; then
            docker compose --file "$compose" up -d
            echo "Waiting for the initial Windows installation and RDP startup..." >&2
            ready=false
            for ((attempt = 0; attempt < 360; attempt++)); do
              if (echo >/dev/tcp/127.0.0.1/3389) >/dev/null 2>&1; then
                ready=true
                break
              fi
              sleep 5
            done
            if [ "$ready" != true ]; then
              echo "Windows did not open RDP within 30 minutes; check docker logs WinApps" >&2
              exit 1
            fi
          fi

          windows_path="\\\\host.lan\\Data\\''${relative//\//\\}"
          exec ${lib.getExe winappsPkg} manual "$windows_path"
        '';
      in
      delib.module {
        name = "osa.apps.winapps";

        options = { myconfig, ... }: {
          osa.apps.winapps.enable = delib.boolOption myconfig.user.gui.enable;
          osa.apps.winapps.pkg = delib.packageOption winapps;
        };

        nixos.ifEnabled =
          { myconfig, ... }:
          let
            inherit (myconfig.user.constants) username;
          in
          {
            nix.settings = {
              extra-substituters = [ "https://winapps.cachix.org" ];
              extra-trusted-public-keys = [
                "winapps.cachix.org-1:HI82jWrXZsQRar/PChgIx1unmuEsiQMQq+zt05CD36g="
              ];
            };

            virtualisation.docker.enable = true;
            virtualisation.docker.storageDriver = lib.mkDefault "overlay2";

            users.users.${username}.extraGroups = [ "docker" ];
          };

        home.ifEnabled =
          { cfg, ... }:
          let
            hm = inputs.home-manager.lib.hm;
          in
          {
            xdg.configFile = {
              "winapps/compose.yaml".text = ''
                name: winapps
                services:
                  windows:
                    image: ghcr.io/dockur/windows:latest
                    container_name: WinApps
                    environment:
                      VERSION: "11"
                      RAM_SIZE: "4G"
                      CPU_CORES: "2"
                      DISK_SIZE: "64G"
                      USERNAME: "winuser"
                      PASSWORD: "''${WINAPPS_PASSWORD}"
                    ports:
                      - "127.0.0.1:3389:3389/tcp"
                      - "127.0.0.1:3389:3389/udp"
                      - "127.0.0.1:8006:8006/tcp"
                    cap_add:
                      - NET_ADMIN
                      - NET_RAW
                    devices:
                      - /dev/kvm
                      - /dev/net/tun
                    stop_grace_period: 2m
                    restart: "no"
                    volumes:
                      - data:/storage
                      - ''${HOME}/Documents/VMShared:/shared
                      - ./oem:/oem:ro
                volumes:
                  data:
              '';
              "winapps/oem".source = "${inputs.winapps}/oem";
              "winapps/winapps.conf".text = ''
                RDP_USER="winuser"
                RDP_PASS="$(cat "$HOME/.config/winapps/password")"
                RDP_IP="127.0.0.1"
                WAFLAVOR="docker"
                FREERDP_COMMAND="${pkgs.freerdp}/bin/xfreerdp"
                RDP_FLAGS="/cert:tofu /sound /microphone +home-drive +clipboard"
                AUTOPAUSE="on"
                AUTOPAUSE_TIME="300"
                BOOT_TIMEOUT="300"
              '';
            };

            home.activation.winappsCredentials = hm.dag.entryAfter [ "writeBoundary" ] ''
              config_dir="$HOME/.config/winapps"
              mkdir -p "$config_dir" "$HOME/Documents/VMShared"
              chmod 700 "$config_dir"
              if [ ! -e "$config_dir/password" ]; then
                umask 077
                ${pkgs.coreutils}/bin/od -An -N24 -tx1 /dev/urandom | ${pkgs.coreutils}/bin/tr -d ' \n' > "$config_dir/password"
              fi
              if [ ! -e "$config_dir/.env" ]; then
                umask 077
                printf 'WINAPPS_PASSWORD=%s\n' "$(cat "$config_dir/password")" > "$config_dir/.env"
              fi
            '';

            home.packages = [
              cfg.pkg
              (winappsExe cfg.pkg)
              (pkgs.callPackage "${inputs.winapps}/packages/winapps-launcher" { winapps = cfg.pkg; })
              pkgs.freerdp
            ];
          };
      }
    ))
  ];
}
