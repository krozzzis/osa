# Build PAM against the host ABI on both supported system channels.
{ pkgs, inputs }:
(pkgs.callPackage "${inputs.nixpkgs-unstable}/pkgs/by-name/oo/oo7-pam/package.nix" { })
.overrideAttrs
  (old: {
    patches = (old.patches or [ ]) ++ [ ./oo7-pam-lifecycle.patch ];
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/socket.rs \
        --replace-fail /usr/bin/oo7-daemon /run/wrappers/bin/oo7-daemon
    '';
    doCheck = true;
    checkPhase = ''
      runHook preCheck
      export CARGO_TARGET_DIR="$TMPDIR/oo7-pam-tests"
      cargo test --offline --locked --manifest-path ../Cargo.toml -p oo7-pam
      runHook postCheck
    '';
  })
