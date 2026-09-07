# A throwaway "host" whose only job is to make `nix flake check` fully
# evaluate every osa module against the `user.*` interface contract
# (see modules/osa/user/default.nix) without needing a real machine.
# Downstream flakes never see this: osa-host scans only `${osa}/modules`,
# never `${osa}/check`.
#
# Enablement mirrors the real niri rice (niri + dms + walker, fish shell)
# on top of `user.gui`/`user.shell`, so both the always-on and gui/shell-
# gated code paths of every module get forced through evaluation.
{ delib, ... }:
delib.host {
  name = "eval-check";

  myconfig = { myconfig, ... }: {
    user.constants.username = "nixos";
    user.constants.useremail = "eval-check@invalid";

    user.gui.enable = true;
    user.shell.enable = true;
    user.shell.default = myconfig.osa.shell.fish;

    osa.de.dms.enable = true;
    osa.apps.walker.enable = true;
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
