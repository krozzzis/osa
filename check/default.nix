# A throwaway "host" whose only job is to make `nix flake check` fully
# evaluate every osa module against the `user.*` interface contract
# (see modules/osa/user/default.nix) without needing a real machine.
# Downstream flakes never see this: osa-host scans only `${osa}/modules`,
# never `${osa}/check`.
#
# Enable all OSA rice bundles at once and select niri as primary. This exercises
# the multi-session display-manager path as well as every compositor/shell pair.
{ delib, ... }:
delib.host {
  name = "eval-check";

  myconfig = { myconfig, ... }: {
    user.constants.username = "nixos";
    user.constants.useremail = "eval-check@invalid";

    user.shell.default = myconfig.osa.shell.fish;
    user.editor.default = myconfig.osa.editor.nixvim;
    user.editor.gui = myconfig.osa.editor.zed;

    osa.apps.rustdesk.enable = true;
    # The test builder supplies this additional named channel.
    osa.apps.rustdesk.nixpkgs = "pinned-test";
    osa.media.obs.nixpkgs = "stable";
    osa.editor.vim.nixpkgs = "unstable";
    osa.editor.vim.pkg = myconfig.osa.nixpkgs.packages.system.vim;

    osa.de.rice.niri.enable = true;
    osa.de.rice.caelestia.enable = true;
    osa.de.rice.xfce.enable = true;
    osa.de.rice.driftwm.enable = true;
    osa.de.rice.primary = "niri";

    # Exercise opt-in branches that are not enabled by the desktop profile.
    osa.apps.wine = {
      enable = true;
      profiles.wine-check = {
        prefix = ".wine-check";
        locale = "ru_RU.UTF-8";
      };
    };
    osa.taskManager.missionCenter.enable = true;
    osa.apps.foliate.enable = true;
    osa.fileManager.dolphin.enable = true;
    osa.fileManager.flux.enable = true;
    osa.apps.cosmic.enable = true;
    osa.apps.polkitLxqtAgent.enable = true;
    osa.browser.chromium.enable = true;
    osa.dev.lsp.basedpyright.enable = true;
    osa.dev.lsp.jsonnet-ls.enable = true;
    osa.dev.lsp.lua-ls.enable = true;
    osa.dev.lsp.nixd.enable = true;
    osa.dev.lsp.ruff.enable = true;
    osa.dev.lsp.rust-analyzer.enable = true;
    osa.dev.lsp.taplo.enable = true;
    osa.dev.mcp.nixos.enable = true;
    osa.dev.mcp.pcap-analyze.enable = true;
    osa.dev.mcp.playwright.enable = true;
    osa.dev.mcp.websearch.enable = true;
    osa.media.lspPlugins.enable = true;
    osa.media.patchbay.enable = true;
    osa.media.vstPath.enable = true;
    osa.network.yggdrasil.enable = true;
    osa.system.printing.enable = true;
    osa.shell.fzf.enable = true;
    osa.system.libvirtd.enable = true;
    osa.system.ntfs.enable = true;
    osa.system.hibernate.enable = true;
    osa.system.hibernate.resumeDevice = "/dev/mapper/eval-check-luks";
    osa.system.hibernate.resumeOffset = 1;
    osa.system.plymouth.enable = true;
  };

  home.home.stateVersion = "26.05";

  # Minimal stand-in for what a real host's hardware/disko/boot modules
  # provide -- just enough plumbing for toplevel eval to pass assertions.
  nixos = {
    system.stateVersion = "26.05";
    imports = [
      ({ config, lib, ... }: {
        assertions =
          let
            home = config.home-manager.users.nixos;
            osa = config.myconfig.osa;
            settings = config.nix.settings;
            caches = map (lib.removeSuffix "/") (
              (settings.substituters or [ ]) ++ (settings.extra-substituters or [ ])
            );
            keys = (settings.trusted-public-keys or [ ]) ++ (settings.extra-trusted-public-keys or [ ]);
            defaults = home.xdg.mimeApps.defaultApplications;
            expected = {
              "image/png" = [ "org.gnome.Loupe.desktop" ];
              "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
              "text/html" = [ "zen-beta.desktop" ];
              "text/plain" = [ "dev.zed.Zed.desktop" ];
              "application/pdf" = [ "org.gnome.Papers.desktop" ];
              "application/epub+zip" = [ "com.github.johnfactotum.Foliate.desktop" ];
              "audio/mpeg" = [ "vlc.desktop" ];
              "video/mp4" = [ "vlc.desktop" ];
              "application/x-msi" = [ "osa-wine.desktop" ];
              "text/csv" = [ "calc.desktop" ];
              "x-scheme-handler/magnet" = [ "org.qbittorrent.qBittorrent.desktop" ];
            };
          in
          [
            {
              assertion = home.dconf.settings."io/missioncenter/MissionCenter".first-time-running == false;
              message = "Mission Center must not run its non-NixOS setup wizard at startup.";
            }
            {
              assertion = lib.elem config.myconfig.user.taskManager.default.pkg home.home.packages;
              message = "The default task manager handle must be installed.";
            }
            {
              assertion = home.home.version.release == config.system.nixos.release;
              message = "Home Manager must match the selected NixOS release.";
            }
            {
              assertion =
                config.security.wrappers.ThroneCore.source == "${osa.apps.throne.pkg}/share/throne/ThroneCore"
                && !(config.security.wrappers.throne-core.enable or false);
              message = "Unstable Throne must use its matching TUN core wrapper on both system channels.";
            }
            {
              assertion = lib.hasInfix "\"org.freedesktop.resolve1.revert\"" config.security.polkit.extraConfig;
              message = "Throne's capability-based DNS policy must include reverting link settings.";
            }
            {
              assertion =
                let
                  portals = map lib.getName (lib.unique config.xdg.portal.extraPortals);
                in
                builtins.length portals == builtins.length (lib.unique portals);
              message = "Portal backends must not install multiple versions of the same user service.";
            }
            {
              assertion = lib.all (
                file:
                !(builtins.elem file.target [
                  ".codex/config.toml"
                  ".config/codex/config.toml"
                ])
              ) (builtins.attrValues home.home.file);
              message = "Codex runtime configuration must stay mutable on both Home Manager releases.";
            }
            {
              assertion =
                (settings.substitute or true)
                && (settings.require-sigs or true)
                &&
                  lib.all
                    (
                      cache:
                      builtins.elem "https://${cache}" caches && lib.any (key: lib.hasPrefix "${cache}-1:" key) keys
                    )
                    [
                      "cache.nixos.org"
                      "niri.cachix.org"
                      "nix-community.cachix.org"
                      "winapps.cachix.org"
                    ];
              message = "Binary caches must retain substitution, signature checks, URLs, and matching public keys.";
            }
            {
              assertion =
                config.security.pam.services.login.rules.auth.oo7.order
                < config.security.pam.services.login.rules.auth.unix.order
                && config.security.pam.services.login.rules.session.oo7.settings.auto_start;
              message = "oo7 must capture the password before sufficient pam_unix succeeds and start during the session.";
            }
            {
              assertion =
                osa.apps.rustdesk.pkg.drvPath == osa.nixpkgs.packages.stable.rustdesk-flutter.drvPath
                && osa.editor.zed.pkg.drvPath == osa.nixpkgs.packages.unstable.zed-editor.drvPath
                && osa.editor.nixvim.pkg.drvPath == osa.nixpkgs.packages.unstable.neovim.drvPath
                && osa.media.obs.pkg.drvPath == osa.nixpkgs.packages.stable.obs-studio.drvPath
                && osa.editor.vim.pkg.drvPath == osa.nixpkgs.packages.system.vim.drvPath
                && home.programs.firefox.package.drvPath == osa.browser.firefox.pkg.drvPath
                && home.programs.librewolf.package.drvPath == osa.browser.librewolf.pkg.drvPath
                && home.programs.wezterm.package.drvPath == osa.terminal.wezterm.pkg.drvPath;
              message = "Application channels and explicit pkg overrides must select the requested derivations.";
            }
            {
              assertion = lib.all (mime: (defaults.${mime} or [ ]) == expected.${mime}) (
                builtins.attrNames expected
              );
              message = "OSA default GUI applications must use their actual desktop IDs.";
            }
            {
              assertion = lib.all (mime: !lib.hasInfix "*" mime) (builtins.attrNames defaults);
              message = "MIME defaults must use concrete types, not wildcard categories.";
            }
            {
              assertion =
                !(builtins.elem home.programs.zed-editor.package home.home.packages)
                &&
                  lib.length (
                    builtins.filter (
                      pkg: lib.hasPrefix "zed-editor-wrapped-" (lib.getName pkg + "-" + lib.getVersion pkg)
                    ) home.home.packages
                  ) == 1;
              message = "Zed must be installed once through Home Manager's wrapper, without the raw package.";
            }
            {
              assertion = builtins.elem "ru_RU.UTF-8/UTF-8" config.i18n.supportedLocales;
              message = "Wine profile locales must be generated on NixOS.";
            }
          ];
      })
    ];
    nixpkgs.hostPlatform = "x86_64-linux";

    boot.loader.grub.enable = false;
    boot.loader.systemd-boot.enable = true;

    # Exercise the initrd systemd + Plymouth password-agent path.  The device
    # only needs to exist at boot, so it is safe for this evaluation host.
    boot.initrd.luks.devices.eval-check.device = "/dev/disk/by-label/eval-check-luks";

    # btrfs on purpose: satisfies services.btrfs.autoScrub (osa.system.optimize).
    fileSystems."/" = {
      device = "/dev/disk/by-label/eval-check";
      fsType = "btrfs";
    };

    users.users.nixos.isNormalUser = true;
  };
}
