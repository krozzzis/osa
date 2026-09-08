{
  delib,
  pkgs,
  inputs,
  lib,
  ...
}:

delib.module {
  name = "osa.apps.winapps";

  options = { myconfig, ... }: {
    osa.apps.winapps.enable = delib.boolOption myconfig.user.gui.enable;
  };

  nixos.ifEnabled =
    { myconfig, ... }:
    let
      inherit (myconfig.user.constants) username;
    in
    {
      virtualisation.docker.enable = true;
      virtualisation.docker.storageDriver = lib.mkDefault "overlay2";

      environment.systemPackages = with pkgs; [
        docker-compose
        freerdp
      ];

      users.users.${username}.extraGroups = [ "docker" ];
    };

  home.ifEnabled =
    { ... }:
    {
      # home.file = {
      #   ".config/winapps/docker-compose.yml".text = ''
      #     name: winapps-windows

      #     services:
      #       windows:
      #         image: ghcr.io/dockur/windows:latest
      #         container_name: winapps-windows
      #         environment:
      #           VERSION: "11-pro"
      #           RAM_SIZE: "4G"
      #           CPU_CORES: "2"
      #           DISK_SIZE: "50G"
      #           USERNAME: "winuser"
      #           PASSWORD: "winpass123"
      #           WORKDIR: "/shared"
      #         ports:
      #           - "127.0.0.1:3389:3389/tcp"
      #           - "127.0.0.1:3389:3389/udp"
      #         cap_add:
      #           - NET_ADMIN
      #         devices:
      #           - /dev/kvm
      #           - /dev/net/tun
      #         stop_grace_period: 2m
      #         restart: unless-stopped
      #         volumes:
      #           - winapps-data:/storage
      #           - /home/${username}/shared:/shared
      #           - ./oem:/oem:ro

      #     volumes:
      #       winapps-data:
      #   '';

      #   ".config/winapps/oem/install.bat".text = ''
      #     @echo off
      #     echo WinApps guest tools installation
      #     echo Done.
      #   '';

      #   ".config/winapps/oem/RDPApps.reg".text = ''
      #     Windows Registry Editor Version 5.00

      #     [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp]
      #     "fEnableWinStation"=dword:00000001
      #   '';

      #   ".config/winapps/winapps.conf".text = ''
      #     RDP_USER="winuser"
      #     RDP_PASS="winpass123"
      #     RDP_DOMAIN=""

      #     RDP_IP="127.0.0.1"
      #     WAFLAVOR="docker"
      #     VM_NAME="WinApps-Docker"

      #     RDP_SCALE="100"
      #     RDP_FLAGS="/cert:tofu /sound /microphone +home-drive +clipboard"

      #     DEBUG="true"

      #     AUTOPAUSE="on"
      #     AUTOPAUSE_TIME="600"

      #     PORT_TIMEOUT="8"
      #     RDP_TIMEOUT="45"
      #     APP_SCAN_TIMEOUT="90"
      #     BOOT_TIMEOUT="180"
      #   '';
      # };

      home.packages = lib.mkAfter [
        inputs.winapps.packages.${pkgs.stdenv.hostPlatform.system}.winapps
        inputs.winapps.packages.${pkgs.stdenv.hostPlatform.system}.winapps-launcher
        pkgs.freerdp
      ];
    };
}
