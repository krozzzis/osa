{
  delib,
  inputs,
  pkgs,
  ...
}:
let
  package = pkgs.stdenvNoCC.mkDerivation {
    pname = "conflux-icon-theme";
    version = inputs.conflux-icon-theme.shortRev or "unstable";
    src = inputs.conflux-icon-theme;

    installPhase = ''
      mkdir -p "$out/share/icons"
      cp -r "$src" "$out/share/icons/Conflux"
    '';
  };
in
delib.module {
  name = "osa.ui.conflux";

  options = { ... }: {
    osa.ui.conflux.enable = delib.boolOption true;
    osa.ui.conflux.pkg = delib.packageOption package;
  };

  nixos.ifEnabled = { cfg, ... }: {
    environment.systemPackages = [ cfg.pkg ];
  };
}
