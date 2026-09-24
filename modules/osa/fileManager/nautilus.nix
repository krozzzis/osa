{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.fileManager.nautilus";

  options = { myconfig, ... }: {
    osa.fileManager.nautilus.enable = delib.boolOption myconfig.user.gui.enable;
    osa.fileManager.nautilus.pkg = delib.packageOption pkgs.nautilus;
  };

  nixos.ifEnabled = { myconfig, ... }: {
    services.gvfs.enable = true;
    services.udisks2.enable = true;

    environment.systemPackages = [
      myconfig.osa.fileManager.nautilus.pkg
      pkgs.usbutils
      pkgs.apfs-fuse
    ];

    boot.supportedFilesystems = [ "ntfs" ];
  };

  home.ifEnabled = { config, ... }: {
    xdg.userDirs = {
      enable = true;
      createDirectories = true;
    };

    # GTK file managers, including Nautilus, read this shared bookmarks file.
    xdg.configFile."gtk-3.0/bookmarks".text = ''
      file://${config.home.homeDirectory}/Downloads Downloads
      file://${config.home.homeDirectory}/Documents Documents
    '';
  };

}
