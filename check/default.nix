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

    osa.de.rice.niri.enable = true;
    osa.de.rice.caelestia.enable = true;
    osa.de.rice.xfce.enable = true;
    osa.de.rice.driftwm.enable = true;
    osa.de.rice.primary = "niri";

    # Exercise opt-in branches that are not enabled by the desktop profile.
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
    osa.shell.fzf.enable = true;
    osa.system.libvirtd.enable = true;
    osa.system.ntfs.enable = true;
    osa.system.hibernate.enable = true;
    osa.system.hibernate.resumeDevice = "/dev/mapper/eval-check-luks";
    osa.system.hibernate.resumeOffset = 1;
    osa.system.plymouth.enable = true;
  };

  home.home.stateVersion = "26.05";
  nixos.system.stateVersion = "26.05";

  # Minimal stand-in for what a real host's hardware/disko/boot modules
  # provide -- just enough plumbing for toplevel eval to pass assertions.
  nixos = {
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
