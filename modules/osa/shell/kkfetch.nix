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
        # Reuse the same wasp artwork as the previous Fastfetch setup.
        logoLines = pkgs.lib.filter (line: line != "") (
          pkgs.lib.splitString "\n" (builtins.readFile ../../../assets/osa-logo.txt)
        );
        logoEntry = ''
          pub const ALL_LOGOS: &[Logo] = &[
              Logo {
                  name: "osa",
                  raw_lines: &[
          ${pkgs.lib.concatMapStringsSep "\n" (line: "            ${builtins.toJSON (pkgs.lib.removePrefix "$1" line)},") logoLines}
                  ],
                  distro_color: "\x1b[33m",
                  outer_color: WHITE_COLOR,
              },
        '';
        package = pkgs.rustPlatform.buildRustPackage {
          pname = "kkfetch";
          version = (builtins.fromTOML (builtins.readFile "${inputs.kkfetch}/Cargo.toml")).package.version;
          src = inputs.kkfetch;
          cargoLock.lockFile = "${inputs.kkfetch}/Cargo.lock";
          nativeBuildInputs = [ pkgs.installShellFiles ];
          postPatch = ''
            substituteInPlace src/output/logo.rs \
              --replace-fail 'pub const ALL_LOGOS: &[Logo] = &[' ${pkgs.lib.escapeShellArg logoEntry}
          '';
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
