{
  delib,
  lib,
  pkgs,
  inputs,
  ...
}:
delib.module {
  name = "osa.de.dms";

  home.ifEnabled =
    { cfg, ... }:
    let
      hm = inputs.home-manager.lib.hm;
      declaredSettings = (pkgs.formats.json { }).generate "osa-dms-settings.json" cfg.settings;
    in
    {
      programs.dank-material-shell = {
        enable = true;
        package = cfg.pkg;
        quickshell.package = cfg.quickshell.pkg;
        systemd = {
          enable = true;
          restartIfChanged = true;
          target = lib.mkDefault "graphical-session.target";
        };
        enableSystemMonitoring = true;
        enableVPN = true;
        enableDynamicTheming = true;
        enableAudioWavelength = true;
        enableCalendarEvents = true;

        # DMS writes runtime state here. Keep the file mutable and let the
        # activation below own only keys declared through OSA settings.
        settings = lib.mkForce { };
      };

      # Multiple installed rice bundles must not start multiple shells.
      systemd.user.services.dms.Unit.ConditionEnvironment = [
        "|XDG_CURRENT_DESKTOP=niri"
        "|XDG_CURRENT_DESKTOP=driftwm"
      ];

      home.activation.fixDmsSettings = hm.dag.entryBefore [ "linkGeneration" ] ''
        settings_file="$HOME/.config/DankMaterialShell/settings.json"
        if [ -L "$settings_file" ]; then
          target=$(${pkgs.coreutils}/bin/readlink "$settings_file")
          case "$target" in
            /nix/store/*)
              ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$settings_file")"
              replacement=$(${pkgs.coreutils}/bin/mktemp "$(${pkgs.coreutils}/bin/dirname "$settings_file")/.settings.XXXXXX")
              ${pkgs.coreutils}/bin/cp --dereference "$settings_file" "$replacement"
              ${pkgs.coreutils}/bin/rm -f "$settings_file"
              ${pkgs.coreutils}/bin/mv "$replacement" "$settings_file"
              ;;
          esac
        fi
      '';

      home.activation.dmsSettings = hm.dag.entryAfter [ "writeBoundary" ] ''
        config_dir="$HOME/.config/DankMaterialShell"
        settings_file="$config_dir/settings.json"
        managed_settings="$config_dir/.osa-settings.json"

        ${pkgs.coreutils}/bin/mkdir -p "$config_dir"
        work_dir=$(${pkgs.coreutils}/bin/mktemp -d "$config_dir/.osa-settings.XXXXXX")
        trap '${pkgs.coreutils}/bin/rm -rf "$work_dir"' EXIT

        if [ -s "$settings_file" ] && ${pkgs.jq}/bin/jq empty "$settings_file" >/dev/null 2>&1; then
          ${pkgs.coreutils}/bin/cp "$settings_file" "$work_dir/current.json"
        else
          ${pkgs.coreutils}/bin/printf '{}\n' > "$work_dir/current.json"
        fi

        if [ -s "$managed_settings" ]; then
          ${pkgs.coreutils}/bin/cp "$managed_settings" "$work_dir/previous.json"
        else
          ${pkgs.coreutils}/bin/printf '{}\n' > "$work_dir/previous.json"
        fi

        ${pkgs.jq}/bin/jq --slurpfile previous "$work_dir/previous.json" \
          --slurpfile declared ${declaredSettings} '
            def remove_managed($mask):
              if type == "object" and ($mask | type) == "object" then
                reduce ($mask | keys[]) as $key (.;
                  if (.[$key] | type) == "object" and ($mask[$key] | type) == "object" then
                    .[$key] |= remove_managed($mask[$key])
                    | if .[$key] == {} then del(.[$key]) else . end
                  else
                    del(.[$key])
                  end
                )
              else . end;
            remove_managed($previous[0]) * $declared[0]
          ' "$work_dir/current.json" > "$work_dir/settings.json"

        ${pkgs.coreutils}/bin/install -m 600 "$work_dir/settings.json" "$settings_file"
        ${pkgs.coreutils}/bin/install -m 600 ${declaredSettings} "$managed_settings"
      '';
    };
}
