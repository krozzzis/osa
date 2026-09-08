{
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "osa.dev.lsp.jsonnet-ls";

  options = delib.singleEnableOption false;

  myconfig.ifEnabled = {
    user.dev.lsp."jsonnet-ls" = {
      enable = true;
      package = if lib.hasAttr "jsonnet-language-server" pkgs then pkgs.jsonnet-language-server else null;
      settings = { };
    };
  };

  home.ifEnabled = {
    home.packages = lib.optionals (lib.hasAttr "jsonnet-language-server" pkgs) [
      pkgs.jsonnet-language-server
    ];
  };
}
