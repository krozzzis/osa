{
  delib,
  inputs,
  pkgs,
  ...
}:
delib.module {
  name = "osa.editor.nixvim";

  options = { myconfig, ... }: {
    osa.editor.nixvim.enable = delib.boolOption myconfig.user.shell.enable;

    osa.editor.nixvim.pkg = delib.packageOption pkgs.neovim;
  };

  home.always.imports = [
    inputs.nixvim.homeModules.nixvim
  ];

  home.ifEnabled = { cfg, ... }: {
    programs.nixvim = {
      enable = true;
      package = cfg.pkg.unwrapped or cfg.pkg;
      nixpkgs.source = inputs.nixpkgs;
    };
  };
}
