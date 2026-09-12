{
  delib,
  lib,
  pkgs,
  inputs,
  ...
}:
delib.module {
  name = "osa.ai.codex";

  options = { myconfig, ... }: {
    osa.ai.codex.enable = delib.boolOption myconfig.user.gui.enable;
    osa.ai.codex.pkg = delib.packageOption pkgs.codex;
    osa.ai.codex.settings = lib.mkOption {
      type = (pkgs.formats.toml { }).type;
      default = { };
      description = "Declarative Codex settings merged into the writable runtime configuration.";
    };
  };

  home.ifEnabled =
    {
      cfg,
      myconfig,
      ...
    }:
    let
      codexBin = lib.getExe cfg.pkg;
      hm = inputs.home-manager.lib.hm;
      settingsJson = (pkgs.formats.json { }).generate "osa-codex-settings.json" cfg.settings;
      inherit (import ../../../lib/mutable-settings.nix) jqMergeFilter;

      enabledLsp = lib.filterAttrs (
        _name: server: server.enable && server.package != null
      ) myconfig.user.dev.lsp;
      enabledMcp = lib.filterAttrs (_name: server: server.enable) myconfig.user.dev.mcp;

      mkMcpAdd =
        name: server:
        let
          escapedName = lib.escapeShellArg name;
        in
        if server.type == "local" then
          ''
            ${codexBin} mcp remove ${escapedName} >/dev/null 2>&1 || true
            ${codexBin} mcp add ${escapedName} -- ${lib.escapeShellArgs server.command}
          ''
        else
          ''
            ${codexBin} mcp remove ${escapedName} >/dev/null 2>&1 || true
            ${codexBin} mcp add ${escapedName} --url ${lib.escapeShellArg server.url}
          '';

      mcpNames = builtins.attrNames enabledMcp;
      mcpAddCommands = lib.mapAttrsToList mkMcpAdd enabledMcp;
      mcpNamesFile = pkgs.writeText "osa-codex-mcp-servers" (
        lib.concatStringsSep "\n" mcpNames + lib.optionalString (mcpNames != [ ]) "\n"
      );
    in
    {
      home.packages = lib.mapAttrsToList (_name: server: server.package) enabledLsp;

      # Codex writes project trust and other runtime state into config.toml.
      # Keep the file writable and merge OSA-owned settings during activation
      # instead of letting Home Manager create an immutable store symlink.
      programs.codex = {
        enable = true;
        package = cfg.pkg;
        settings = lib.mkForce null;
      };
      home.sessionVariables.CODEX_HOME = lib.mkForce "$HOME/.codex";

      home.activation.fixCodexConfig = hm.dag.entryBefore [ "linkGeneration" ] ''
        for p in "$HOME/.codex/config.toml" "$HOME/.config/codex/config.toml"; do
          if [ -L "$p" ]; then
            target=$(${pkgs.coreutils}/bin/readlink "$p")
            case "$target" in
              /nix/store/*)
                ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$p")"
                replacement=$(${pkgs.coreutils}/bin/mktemp "$(${pkgs.coreutils}/bin/dirname "$p")/.codex-config.XXXXXX")
                if [ -f "$p" ]; then
                  ${pkgs.coreutils}/bin/cp --dereference "$p" "$replacement"
                fi
                ${pkgs.coreutils}/bin/rm -f "$p"
                ${pkgs.coreutils}/bin/mv "$replacement" "$p"
                ${pkgs.coreutils}/bin/chmod 600 "$p"
                ;;
            esac
          fi
        done
      '';

      home.activation.codexConfig = hm.dag.entryAfter [ "writeBoundary" ] ''
        export CODEX_HOME="$HOME/.codex"
        config_file="$CODEX_HOME/config.toml"
        managed_settings="$CODEX_HOME/.osa-settings.json"
        managed_mcp="$CODEX_HOME/.osa-mcp-servers"

        ${pkgs.coreutils}/bin/mkdir -p "$CODEX_HOME"
        work_dir=$(${pkgs.coreutils}/bin/mktemp -d "$CODEX_HOME/.osa-config.XXXXXX")
        trap '${pkgs.coreutils}/bin/rm -rf "$work_dir"' EXIT

        if [ -s "$config_file" ]; then
          ${pkgs.remarshal}/bin/remarshal --if toml --of json "$config_file" "$work_dir/current.json"
        else
          ${pkgs.coreutils}/bin/printf '{}\n' > "$work_dir/current.json"
        fi

        if [ -s "$managed_settings" ]; then
          ${pkgs.coreutils}/bin/cp "$managed_settings" "$work_dir/previous.json"
        else
          ${pkgs.coreutils}/bin/printf '{}\n' > "$work_dir/previous.json"
        fi

        ${pkgs.jq}/bin/jq --slurpfile previous "$work_dir/previous.json" \
          --slurpfile declared ${settingsJson} \
          ${lib.escapeShellArg jqMergeFilter} \
          "$work_dir/current.json" > "$work_dir/merged.json"

        ${pkgs.remarshal}/bin/remarshal --if json --of toml "$work_dir/merged.json" "$work_dir/config.toml"
        ${pkgs.coreutils}/bin/install -m 600 "$work_dir/config.toml" "$config_file"
        ${pkgs.coreutils}/bin/install -m 600 ${settingsJson} "$managed_settings"

        if [ -f "$managed_mcp" ]; then
          while IFS= read -r name; do
            [ -n "$name" ] || continue
            ${codexBin} mcp remove "$name" >/dev/null 2>&1 || true
          done < "$managed_mcp"
        fi

        ${lib.concatStringsSep "\n" mcpAddCommands}
        ${pkgs.coreutils}/bin/install -m 600 ${mcpNamesFile} "$managed_mcp"
      '';
    };
}
