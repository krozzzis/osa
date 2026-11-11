{ inputs, system }:
let
  checkChannel =
    source:
    let
      pkgs = import source { inherit system; };
      pam = import ../compat/oo7-pam.nix { inherit pkgs inputs; };
    in
    pkgs.runCommand "osa-oo7-pam-${pkgs.lib.version}"
      {
        nativeBuildInputs = [
          pkgs.stdenv.cc
          pkgs.python3
        ];
        buildInputs = [ pkgs.pam ];
      }
      ''
        cc -shared -fPIC -DFIXTURE ${../../check/oo7-pam.c} -lpam -o fixture.so
        cc ${../../check/oo7-pam.c} -lpam -o pam-caller
        python3 ${../../check/oo7-pam.py} "$PWD/pam-caller" "$PWD/fixture.so" \
          ${pam}/lib/security/pam_oo7.so ${pkgs.pam}/lib/security/pam_permit.so
        touch "$out"
      '';
  stable = checkChannel inputs.nixpkgs-stable;
  unstable = checkChannel inputs.nixpkgs-unstable;
  pkgs = import inputs.nixpkgs { inherit system; };
in
pkgs.runCommand "osa-oo7-pam-check" { } ''
  test -e ${stable}
  test -e ${unstable}
  touch "$out"
''
