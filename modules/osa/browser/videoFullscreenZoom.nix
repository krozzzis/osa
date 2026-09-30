{
  config,
  delib,
  inputs,
  lib,
  ...
}:
let
  pkgs = config.myconfig.osa.nixpkgs.packages.${config.myconfig.osa.browser.zenBrowser.nixpkgs};
  zen = import inputs.zen-browser { inherit pkgs; };
  provisioningDir = pkgs.writeTextDir "tm.json" (builtins.readFile ./videoFullscreenZoom/provisioning.json);
  provisioningHash = lib.removeSuffix "\n" (builtins.readFile ./videoFullscreenZoom/provisioning-hash.txt);
  tampermonkey = pkgs.fetchurl {
    # Signed upstream Firefox beta, v5.6.6239. This version supports
    # jsonImport provisioning through managed extension storage.
    url = "https://firefox.tampermonkey.net/firefox-current-beta.xpi";
    hash = "sha256-Y7Ogbyjg8+ywvqinARCTaokLGCe1I85RPqxrhptY0w4=";
  };
  zoomPolicies = {
    "3rdparty".Extensions."firefoxbeta@tampermonkey.net".jsonImport = [
      {
        hash = provisioningHash;
        url = "http://127.0.0.1:17837/tm.json";
        haltOnError = false;
        installAsSystemScripts = false;
      }
    ];
    ExtensionSettings."firefoxbeta@tampermonkey.net" = {
      installation_mode = "normal_installed";
      install_url = "file://${tampermonkey}";
      updates_disabled = true;
    };
  };
  unwrapped = zen.default.unwrapped.override { extraPolicies = zoomPolicies; };
  wrapZen = import "${inputs.zen-browser}/wrap-zen.nix" pkgs.wrapFirefox;
  zoomPkg = wrapZen unwrapped { icon = "zen-browser"; };
in
delib.module {
  name = "osa.browser.videoFullscreenZoom";
  options = delib.singleEnableOption false;

  myconfig.ifEnabled.osa.browser.zenBrowser.pkg = lib.mkDefault zoomPkg;

  home.ifEnabled = {
    systemd.user.sockets.osa-zen-video-fullscreen-zoom = {
      Unit.Description = "Local Zen video fullscreen zoom provisioning socket";
      Socket.ListenStream = "127.0.0.1:17837";
      Install.WantedBy = [ "sockets.target" ];
    };

    systemd.user.services.osa-zen-video-fullscreen-zoom = {
      Unit.Description = "Serve local Zen video fullscreen zoom script";
      Service = {
        ExecStart = "${pkgs.python3}/bin/python3 ${./videoFullscreenZoom/serve.py} ${provisioningDir}";
        NoNewPrivileges = true;
      };
    };
  };
}
