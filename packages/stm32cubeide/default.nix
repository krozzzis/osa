{ pkgs }:
let
  version = "2.2.0";
  payload = pkgs.stdenvNoCC.mkDerivation {
    pname = "stm32cubeide-unwrapped";
    inherit version;
    src = pkgs.requireFile {
      name = "stm32cubeide_2.2.0-Lin-Deb-x86_64.sh.zip";
      hash = "sha256-UNgjUatfee240GvxlFobs8NccsanNmX6LNV+k3axZjg=";
      message = ''
        Download STM32CubeIDE 2.2.0 (Debian Linux installer) from
        https://www.st.com/en/development-tools/stm32cubeide.html
        and add it with:
          nix store add-file stm32cubeide_2.2.0-Lin-Deb-x86_64.sh.zip
      '';
    };
    nativeBuildInputs = [
      pkgs.unzip
      pkgs.dpkg
    ];
    dontUnpack = true;
    dontFixup = true;
    installPhase = ''
      runHook preInstall
      unzip -q "$src"
      # Extract the Makeself payload only; never run the system installer.
      bash stm32cubeide_*-Lin-Deb-x86_64.sh --noexec --nochown --quiet --target installer
      mkdir -p "$out"
      for deb in installer/stm32cubeide-*.deb installer/st-stlink-server-*.deb installer/st-stlink-udev-rules-*.deb; do
        dpkg-deb -x "$deb" "$out"
      done
      runHook postInstall
    '';
  };
  launcher = pkgs.writeShellScript "stm32cubeide-launch" ''
    export _JAVA_AWT_WM_NONREPARENTING=1
    # Match ST's stm32cubeide_wayland launcher for the bundled Eclipse/SWT.
    export GDK_BACKEND=x11
    export PATH=${payload}/usr/bin:"$PATH"
    exec ${payload}/opt/st/stm32cubeide_${version}/stm32cubeide "$@"
  '';
  desktop = pkgs.makeDesktopItem {
    name = "stm32cubeide";
    desktopName = "STM32CubeIDE";
    exec = "stm32cubeide %F";
    icon = "${payload}/opt/st/stm32cubeide_${version}/icon.xpm";
    categories = [
      "Development"
      "IDE"
    ];
    startupWMClass = "STM32CubeIDE";
  };
in
pkgs.buildFHSEnv {
  pname = "stm32cubeide";
  inherit version;
  runScript = launcher;
  targetPkgs =
    p: with p; [
      alsa-lib
      atk
      cairo
      cups
      dbus
      expat
      fontconfig
      freetype
      glib
      gtk3
      libGL
      libsecret
      libusb1
      libx11
      libxcursor
      libxext
      libxfixes
      libxi
      libxrandr
      libxrender
      libxtst
      ncurses5
      openssl
      pango
      stdenv.cc.cc.lib
      udev
      zlib
    ];
  extraBuildCommands = ''
    ln -s ${payload}/usr/bin/stlink-server "$out/usr/bin/stlink-server"
  '';
  extraInstallCommands = ''
    mkdir -p "$out/share/applications" "$out/lib/udev"
    cp ${desktop}/share/applications/* "$out/share/applications/"
    ln -s ${payload}/etc/udev/rules.d "$out/lib/udev/rules.d"
  '';
  meta = {
    description = "STM32 development IDE with bundled compiler and debugger";
    homepage = "https://www.st.com/en/development-tools/stm32cubeide.html";
    license = pkgs.lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "stm32cubeide";
  };
}
