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

      # Upstream ships a few symlinks to icons that are not in this release.
      # They cannot resolve at runtime and Nix rejects dangling symlinks during
      # fixup, so drop only those links while preserving all valid aliases.
      chmod -R u+w "$out/share/icons/Conflux"
      find "$out/share/icons/Conflux" -type l ! -exec test -e {} \; -delete
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
