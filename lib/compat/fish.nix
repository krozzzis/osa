# Home Manager 26.05 expects an on-disk script; newer Fish embeds it.
# Patch only the old generator reference, retaining the selected HM module.
{ homeManager }:
let
  source = builtins.readFile "${homeManager}/modules/programs/fish.nix";
  oldPath = "\${cfg.package}/share/fish/tools/create_manpage_completions.py";
  needsCompat = builtins.replaceStrings [ oldPath ] [ "" ] source != source;
  patched =
    builtins.replaceStrings
      [ "cfg = config.programs.fish;" oldPath ]
      [
        ''
          cfg = config.programs.fish;
          osaManpageGenerator = pkgs.runCommand "fish-manpage-generator" {
            nativeBuildInputs = [ cfg.package ];
          } ${"''"}
            script=''${cfg.package}/share/fish/tools/create_manpage_completions.py
            if [ -f "$script" ]; then
              cp "$script" "$out"
            else
              fish --no-config -c 'status get-file tools/create_manpage_completions.py' > "$out"
            fi
          ${"''"};
        ''
        "\${osaManpageGenerator}"
      ]
      source;
in
{
  disabledModules = if needsCompat then [ "programs/fish.nix" ] else [ ];
  imports = if needsCompat then [ (builtins.toFile "osa-home-manager-fish.nix" patched) ] else [ ];
}
