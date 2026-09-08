{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.apps.gparted";

  options = { myconfig, ... }: {
    osa.apps.gparted.enable = delib.boolOption myconfig.user.gui.enable;
  };

  home.ifEnabled = {
    home.packages = with pkgs; [
      # gparted's own polkit action (org.gnome.gparted, allow_gui=true)
      # never actually applies here -- it's only registered with polkitd
      # for packages listed in NixOS's own environment.systemPackages,
      # and gparted isn't (deliberately: its own .desktop file execs the
      # raw, non-elevated binary, so adding it there would give walker a
      # second, broken "GParted" entry next to this one). So pkexec falls
      # back to the generic exec action, which strips DISPLAY entirely --
      # forward it ourselves.
      #
      # That alone isn't enough either: this session's XWayland
      # (xwayland-satellite) enforces per-UID access control (`xhost`)
      # rather than a cookie file (there's no ~/.Xauthority at all), and
      # only the krozzzis UID is authorized by default -- root's
      # connection gets refused with "Authorization required, but no
      # authorization protocol specified" even with DISPLAY set
      # correctly. Grant root access for this X session before elevating;
      # confirmed via `xhost` that this is the actual gate, not a missing
      # DISPLAY/XAUTHORITY value.
      (writeShellScriptBin "gparted" ''
        set -euo pipefail
        # Launchers that spawn us without a controlling terminal (walker/
        # elephant, via niri's `spawn` action) hand this script stdio that
        # isn't safely writable. `xhost`/`pkexec` writing to a broken
        # stdout/stderr then trips SIGPIPE, and `set -e` kills the script
        # before pkexec ever execs gparted -- silently, since the error
        # message itself can't be written either. Terminals and DMS's own
        # launcher (which gives child processes real pipes) don't hit
        # this, which is why it only ever failed from walker. Give
        # ourselves stdio that's always valid, independent of the caller.
        exec </dev/null >/dev/null 2>&1
        ${xhost}/bin/xhost +si:localuser:root
        # Revoke root's X access as soon as this script exits -- the grant
        # is only needed for the duration of the elevated launch. That
        # rules out `exec` here (an EXIT trap never fires across exec),
        # so run pkexec as a child and propagate its status explicitly.
        trap '${xhost}/bin/xhost -si:localuser:root >/dev/null 2>&1 || true' EXIT
        # Absolute path, not bare `env`: this system's uutils-coreutils is
        # hiPrio'd ahead of GNU coreutils on $PATH, and pkexec resolves
        # PROGRAM through its own restricted lookup, which landed on
        # uutils' multicall binary and choked on DISPLAY=:0 as if it were
        # an applet name ("coreutils: unknown program"). Bypass all of
        # that by baking in the real GNU coreutils env directly.
        pkexec "${coreutils}/bin/env" DISPLAY="$DISPLAY" "${gparted}/bin/gparted" "$@"
      '')
      # gparted's own .desktop file `Exec`s the raw (non-elevated)
      # binary directly, which is useless here since it needs pkexec.
      # Point a desktop entry at our wrapper instead so it shows up in
      # walker.
      (makeDesktopItem {
        name = "gparted";
        desktopName = "GParted";
        genericName = "Partition Editor";
        comment = "Create, reorganize, and delete partitions";
        icon = "${gparted}/share/icons/hicolor/scalable/apps/gparted.svg";
        exec = "gparted";
        categories = [
          "GNOME"
          "System"
          "Filesystem"
        ];
        terminal = false;
      })
    ];
  };
}
