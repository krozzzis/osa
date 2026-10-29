{
  delib,
  inputs,
  ...
}:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.shell.kkfetch" (
      { pkgs }:
      let
        package = pkgs.rustPlatform.buildRustPackage {
          pname = "kkfetch";
          version = (builtins.fromTOML (builtins.readFile "${inputs.kkfetch}/Cargo.toml")).package.version;
          src = inputs.kkfetch;
          cargoLock.lockFile = "${inputs.kkfetch}/Cargo.lock";
          nativeBuildInputs = [ pkgs.installShellFiles ];
          postInstall = ''
            installShellCompletion --cmd kkfetch \
              --bash completions/kkfetch.bash \
              --fish completions/kkfetch.fish \
              --zsh completions/_kkfetch
          '';
          meta.mainProgram = "kkfetch";
        };
      in
      delib.module {
        name = "osa.shell.kkfetch";

        options = { myconfig, ... }: {
          osa.shell.kkfetch.enable = delib.boolOption myconfig.user.shell.enable;
          osa.shell.kkfetch.pkg = delib.packageOption package;
        };

        home.ifEnabled = { cfg, ... }: {
          home.packages = [ cfg.pkg ];
        };
      }
    ))
  ];
}
