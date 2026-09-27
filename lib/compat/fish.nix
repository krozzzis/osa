# NixOS and Home Manager 26.05 expect an on-disk script; newer Fish embeds it.
# Keep each selected module, including NixOS's completion collision patch.
{
  homeManager ? null,
  nixpkgs ? null,
}:
assert (homeManager == null) != (nixpkgs == null);
let
  moduleDirectory =
    if nixpkgs != null then "${nixpkgs}/nixos/modules/programs" else "${homeManager}/modules/programs";
  source = builtins.readFile "${moduleDirectory}/fish.nix";
  oldPath = "\${cfg.package}/share/fish/tools/create_manpage_completions.py";
  needsCompat = builtins.replaceStrings [ oldPath ] [ "" ] source != source;
  patched =
    builtins.replaceStrings
      [ "cfg = config.programs.fish;" oldPath "./fish_completion-generator.patch" ]
      [
        ''
          cfg = config.programs.fish;
          osaManpageGenerator = pkgs.runCommand "fish-manpage-generator" {
            nativeBuildInputs = [ cfg.package ];
          } ${"''"}
            mkdir -p "$out"
            script=''${cfg.package}/share/fish/tools/create_manpage_completions.py
            if [ -f "$script" ]; then
              cp "$script" "$out/create_manpage_completions.py"
            else
              fish --no-config -c 'status get-file tools/create_manpage_completions.py' > "$out/create_manpage_completions.py"
            fi
          ${"''"};
        ''
        "\${osaManpageGenerator}/create_manpage_completions.py"
        "${moduleDirectory}/fish_completion-generator.patch"
      ]
      source;
in
{
  disabledModules = if needsCompat then [ "programs/fish.nix" ] else [ ];
  imports = if needsCompat then [ (builtins.toFile "osa-compatible-fish.nix" patched) ] else [ ];
}
