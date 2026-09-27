{
  lib,
  stdenv,
  xvfb-run,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  wrapGAppsHook4,
  gtk4,
  libadwaita,
  poppler,
  fontconfig,
  gettext,
  python3,
  xdg-utils,
  shared-mime-info,
}:
rustPlatform.buildRustPackage {
  pname = "flux-fm";
  version = "0.1.9-unstable-2026-09-27";

  src = fetchFromGitHub {
    owner = "killown";
    repo = "flux";
    rev = "f1fd2e5448ba8adbbd2bcc13f2d2cb1e79160965";
    hash = "sha256:0gcp146scf878vd4nbv4ma10yybhyz2y2l1ycnmmz042gf3ncbvl";
  };
  cargoHash = "sha256-OHKOaZ582uoWoorG5KleFHiD01l4+908qZXuvOV0eds=";
  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook4
    gettext
  ];
  buildInputs = [
    gtk4
    libadwaita
    poppler
    fontconfig
  ];

  postPatch = ''
    substituteInPlace $(find src -name '*.rs') \
      --replace '/usr/share/flux' "$out/share/flux" \
      --replace '/app/share/flux' "$out/share/flux" \
      --replace '$HOME/.local/share/flux/scripts' "$out/share/flux/scripts" \
      --replace '/usr/bin/python' '${python3}/bin/python3' \
      --replace '/usr/share/mime' '${shared-mime-info}/share/mime'
    substituteInPlace src/i18n.rs \
      --replace-fail 'format!("{}/.local/share/locale", home)' "format!(\"$out/share/locale\")"
    substituteInPlace menus/*.rs \
      --replace '$HOME/.local/share/flux/scripts' "$out/share/flux/scripts" \
      --replace '/usr/bin/python' '${python3}/bin/python3'
  '';
  # Upstream's widget test initializes GTK and needs a display in the sandbox.
  nativeCheckInputs = [ xvfb-run ];
  checkPhase = ''
    runHook preCheck
    xvfb-run -a cargo test --offline --release \
      --target ${stdenv.hostPlatform.rust.rustcTarget} -j "$NIX_BUILD_CORES"
    runHook postCheck
  '';
  postInstall = ''
    # Install only pinned, bundled assets. Upstream make install downloads
    # community themes and mutates the user's configuration.
    install -Dm644 flux.svg $out/share/icons/hicolor/scalable/apps/io.github.killown.flux.svg
    install -Dm644 packaging/flatpak/io.github.killown.flux.metainfo.xml $out/share/metainfo/io.github.killown.flux.metainfo.xml
    mkdir -p $out/share/applications $out/share/flux/icons
    substitute flux.desktop.in $out/share/applications/io.github.killown.flux.desktop \
      --replace-fail @BIN_PATH@ $out/bin/flux-fm
    cp -r themes menus scripts $out/share/flux/
    cp themes/default.css $out/share/flux/style.css
    cp template.svg $out/share/flux/icons/
    cp assets/nerd_fonts.json $out/share/flux/
    make translations PREFIX=$out
  '';
  preFixup = ''
    gappsWrapperArgs+=(--prefix PATH : ${
      lib.makeBinPath [
        python3
        xdg-utils
      ]
    })
  '';
  meta = {
    description = "GTK4/Libadwaita file manager";
    homepage = "https://github.com/killown/flux";
    license = lib.licenses.gpl3Only;
    mainProgram = "flux-fm";
    platforms = lib.platforms.linux;
  };
}
