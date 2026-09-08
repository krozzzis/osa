{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.media.lspPlugins";

  options = { ... }: {
    osa.media.lspPlugins.enable = delib.boolOption false;
    osa.media.lspPlugins.pkg = delib.packageOption pkgs.lsp-plugins;
  };

  # LSP (Linux Studio Plugins) ships LV2/VST2/VST3/CLAP/LADSPA builds. Expose
  # them to every plugin host (MuseScore, Reaper, ...) via the shared
  # `*_PATH` session variables instead of letting each app scan /usr/lib.
  myconfig.ifEnabled = { cfg, ... }: {
    osa.media.vstPath.enable = true;
    osa.media.vstPath.plugins = [ cfg.pkg ];
  };
}
