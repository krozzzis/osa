{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

let
  version = "0.2.34";

  # sha256 values published in the npm package's `binaryChecksums` field,
  # keyed by release target name (the npm wrapper verifies against these
  # same hashes, so they are the release's own integrity data). The AUR
  # freebuff-bin recipe pins the identical values.
  hashes = {
    "linux-x64" = "sha256-XZ8YtaVqyA5FdUfKOFl2aij9jd0yw5ZJLyzbKLklB+I=";
    "linux-arm64" = "sha256-o07zZJM0lqtu7CHiI1XfnIStgbhH9RqIOxmy5IZvDdk=";
  };

  target = if stdenv.hostPlatform.isAarch64 then "linux-arm64" else "linux-x64";

  src = fetchurl {
    url = "https://codebuff.com/api/releases/download/${version}/freebuff-${target}.tar.gz";
    hash = hashes.${target};
  };
in
stdenv.mkDerivation {
  pname = "freebuff";
  inherit version src;

  nativeBuildInputs = [ autoPatchelfHook ];

  # The release ships a dynamically linked bun-compiled binary with no
  # directory entry, so stdenv needs the hooks pointed at the extracted root.
  sourceRoot = ".";

  # Runtime libs of the prebuilt bun binary; autoPatchelfHook rewires the
  # interpreter to the host ABI so it runs on NixOS.
  buildInputs = [ stdenv.cc.cc.lib ];

  # The archive holds `freebuff` and `tree-sitter.wasm` at its root.
  installPhase = ''
    runHook preInstall
    install -Dm755 freebuff "$out/bin/freebuff"
    # The CLI loads tree-sitter.wasm from its own directory at startup.
    install -Dm644 tree-sitter.wasm "$out/bin/tree-sitter.wasm"
    runHook postInstall
  '';

  meta = {
    description = "Freebuff coding agent";
    homepage = "https://freebuff.com";
    license = lib.licenses.asl20;
    mainProgram = "freebuff";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
