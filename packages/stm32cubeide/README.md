# STM32CubeIDE

OSA packages the ST Debian installer in an FHS environment, retaining the bundled
JRE, toolchain and debugger. It does not run the host installer or install via apt.

Download **STM32CubeIDE 2.2.0, Debian Linux x86_64** from
<https://www.st.com/en/development-tools/stm32cubeide.html>, then import the original
ZIP (without renaming it):

```sh
nix store add-file stm32cubeide_2.2.0-Lin-Deb-x86_64.sh.zip
```

Enable `osa.apps.stm32cubeide.enable` downstream. The module installs the desktop
entry, ST-Link udev rules and adds the configured user to `dialout`. Log in again
for new group membership to apply. Existing devices may need to be reconnected
after activation. SEGGER J-Link rules are not installed.

`osa.apps.stm32cubeide.nixpkgs` selects the runtime dependencies, while `.pkg`
replaces the complete package. The ST source version remains fixed independently
of the selected dependency channel. GUI launch uses ST's X11 workaround for SWT
and the AWT non-reparenting workaround for Xwayland.

CubeMX is a separate opt-in module: `osa.apps.stm32cubemx.enable`.
