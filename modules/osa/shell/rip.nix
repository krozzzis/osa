{
  delib,
  inputs,
  ...
}:
{
  imports = [
    ((import ../../../lib/package-module.nix) "osa.shell.rip" (
      { pkgs }:
      let
        # Upstream's flake uses deprecated stdenv.isDarwin and reimports pkgs.
        package = pkgs.rustPlatform.buildRustPackage {
          pname = "rip-cli";
          version = "0.1.0";
          src = inputs.rip;
          cargoLock.lockFile = "${inputs.rip}/Cargo.lock";
          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
            pkgs.apple-sdk
          ];
          meta = {
            description = "Fuzzy find and kill processes from your terminal";
            homepage = "https://github.com/cesarferreira/rip";
            license = pkgs.lib.licenses.mit;
            mainProgram = "rip";
          };
        };
      in
      delib.module {
        name = "osa.shell.rip";

        options = { myconfig, ... }: {
          osa.shell.rip.enable = delib.boolOption myconfig.user.shell.enable;
          osa.shell.rip.pkg = delib.packageOption package;
        };

        home.ifEnabled = { cfg, ... }: {
          home.packages = [ cfg.pkg ];
        };
      }
    ))
  ];
}
