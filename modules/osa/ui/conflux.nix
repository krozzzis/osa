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

      # Keep Conflux as the selected theme, with MoreWaita filling in the
      # application and system icons it does not provide.  MoreWaita follows
      # the Adwaita visual language and itself relies on Adwaita for the core
      # symbolic icons, so include both inherited themes in the same package.
      ln -s "${pkgs.morewaita-icon-theme}/share/icons/MoreWaita" \
        "$out/share/icons/MoreWaita"
      ln -s "${pkgs.adwaita-icon-theme}/share/icons/Adwaita" \
        "$out/share/icons/Adwaita"

      # The upstream theme currently inherits only Adwaita.  Add MoreWaita
      # ahead of it, preserving Conflux as the first lookup source.
      sed -i 's/^Inherits=.*/Inherits=MoreWaita,Adwaita,hicolor/' \
        "$out/share/icons/Conflux/index.theme"
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
