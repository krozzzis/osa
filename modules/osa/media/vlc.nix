{
  delib,
  pkgs,
  ...
}:
let
  vlc = pkgs.symlinkJoin {
    name = "vlc-no-video-autoresize";
    paths = [ pkgs.vlc ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/vlc --add-flags --no-qt-video-autoresize

      rm $out/share/applications/vlc.desktop
      cp ${pkgs.vlc}/share/applications/vlc.desktop $out/share/applications/vlc.desktop
      substituteInPlace $out/share/applications/vlc.desktop \
        --replace-fail '${pkgs.vlc}/bin/vlc' "$out/bin/vlc"
    '';
    meta.mainProgram = "vlc";
  };
in
delib.module {
  name = "osa.media.vlc";

  options = { myconfig, ... }: {
    osa.media.vlc.enable = delib.boolOption myconfig.user.gui.enable;
    osa.media.vlc.pkg = delib.packageOption vlc;
  };

  nixos.ifEnabled = { myconfig, ... }: {
    environment.systemPackages = [
      myconfig.osa.media.vlc.pkg
    ];
  };
}
