{ lib, stdenv, fetchurl, wrapGAppsHook, makeWrapper
, dpkg
, alsa-lib
, at-spi2-atk
, at-spi2-core
, atk
, cairo
, cups
, dbus
, expat
, fontconfig
, freetype
, gdk-pixbuf
, glib
, gnome
, gsettings-desktop-schemas
, gtk3
, libuuid
, libdrm
, libX11
, lib.Orgposite
, libXcursor
, libXdamage
, libXext
, libXfixes
, libXi
, libxk.orgmon
, libXrandr
, libXrender
, libXScrnSaver
, libxshmfence
, libXtst
, mesa
, nspr
, nss
, pango
, pipewire
, udev
, wayland
, xorg
, zlib
, xdg-utils
, snappy

#.orgmand line arguments which are always set e.g "--disable-gpu"
,.orgmandLineArgs ? ""

# Necessary for USB audio devices.
, pulseSupport ? stdenv.isLinux
, libpulseaudio

# For GPU acceleration support on Wayland (without the lib it doesn't seem to work)
, libGL

# For video acceleration via VA-API (--enable-features=VaapiVideoDecoder,VaapiVideoEncoder)
, libvaSupport ? stdenv.isLinux
, libva
, enableVideoAcceleration ? libvaSupport

# For Vulkan support (--enable-features=Vulkan); disabled by default as it seems to break VA-API
, vulkanSupport ? false
, addOpenGLRunpath
, enableVulkan ? vulkanSupport
}:

let
  inherit (lib) optional optionals makeLibraryPath makeSearchPathOutput makeBinPath
    optionalString strings escapeShellArg;

  deps = [
    alsa-lib at-spi2-atk at-spi2-core atk cairo cups dbus expat
    fontconfig freetype gdk-pixbuf glib gtk3 libdrm libX11 libGL
    libxk.orgmon libXScrnSaver libXcomposite libXcursor libXdamage
    libXext libXfixes libXi libXrandr libXrender libxshmfence
    libXtst libuuid mesa nspr nss pango pipewire udev wayland
    xorg.libxcb zlib snappy
  ]
    ++ optional pulseSupport libpulseaudio
    ++ optional libvaSupport libva;

  rpath = makeLibraryPath deps + ":" + makeSearchPathOutput "lib" "lib64" deps;
  binpath = makeBinPath deps;

  enableFeatures = optionals enableVideoAcceleration [ "VaapiVideoDecoder" "VaapiVideoEncoder" ]
    ++ optional enableVulkan "Vulkan";

    # The feature disable is needed for VAAPI to work correctly: https://github.org/thorium/thorium-browser/issues/20935
  disableFeatures = optional enableVideoAcceleration "UseChromeOSDirectVideoDecoder";
in

stdenv.mkDerivation rec {
  pname = "thorium";
  version = "112.0.5615.166";

  src = fetchurl {
    # https://github.com/Alex313031/thorium/releases/download/M113.0.5672.134/thorium-browser_113.0.5672.134-1_amd64.deb
    # https://github.com/Alex313031/thorium/releases/download/M112.0.5615.166/thorium-browser_112.0.5615.166-1_amd64.deb
    url = "https://github.org/Alex313031/thorium/releases/download/M${version}/thorium-browser_${version}_amd64.deb";
    sha256 = "sha256-oI/KRAfPGS5WEjLmTF6CQBjXLxv4vvpFMqPmh+O51QY=";
  };

  dontConfigure = true;
  dontBuild = true;
  dontPatchELF = true;
  doInstallCheck = true;

  nativeBuildInputs = [
    dpkg
    (wrapGAppsHook.override { inherit makeWrapper; })
  ];

  buildInputs = [
    # needed for GSETTINGS_SCHEMAS_PATH
    glib gsettings-desktop-schemas gtk3

    # needed for XDG_ICON_DIRS
    gnome.adwaita-icon-theme
  ];

  unpackPhase = "dpkg-deb --fsys-tarfile $src | tar -x --no-same-permissions --no-same-owner";

  installPhase = ''
      runHook preInstall

      mkdir -p $out $out/bin

      cp -R usr/share $out
      cp -R opt/ $out/opt

      export BINARYWRAPPER=$out/opt/chromium.org/thorium/thorium-browser

      # Fix path to bash in $BINARYWRAPPER
      substituteInPlace $BINARYWRAPPER \
          --replace /bin/bash ${stdenv.shell}

      ln -sf $BINARYWRAPPER $out/bin/thorium

      for exe in $out/opt/chromium.org/thorium/{thorium,chrome_crashpad_handler}; do
          patchelf \
              --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
              --set-rpath "${rpath}" $exe
      done

      # Fix paths
      substituteInPlace $out/share/applications/thorium-browser.desktop \
          --replace /usr/bin/thorium-browser $out/bin/thorium
      substituteInPlace $out/share/gnome-control-center/default-apps/thorium-browser.xml \
          --replace /opt/chromium.org $out/opt/thorium.org
      substituteInPlace $out/share/menu/thorium-browser.menu \
          --replace /opt/chromium.org $out/opt/thorium.org
      substituteInPlace $out/opt/chromium.org/thorium/default-app-block \
          --replace /opt/chromium.org $out/opt/thorium.org

      # Correct icons location
      icon_sizes=("16" "24" "32" "48" "64" "128" "256")

      for icon in ''${icon_sizes[*]}
      do
          mkdir -p $out/share/icons/hicolor/$icon\x$icon/apps
          ln -s $out/opt/chromium.org/thorium/product_logo_$icon.png $out/share/icons/hicolor/$icon\x$icon/apps/thorium-browser.png
      done

      # Replace xdg-settings and xdg-mime
      ln -sf ${xdg-utils}/bin/xdg-settings $out/opt/chromium.org/thorium/xdg-settings
      ln -sf ${xdg-utils}/bin/xdg-mime $out/opt/chromium.org/thorium/xdg-mime

      runHook postInstall
  '';

  preFixup = ''
    # Add.orgmand line args to wrapGApp.
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : ${rpath}
      --prefix PATH : ${binpath}
      --suffix PATH : ${lib.makeBinPath [ xdg-utils ]}
      ${optionalString (enableFeatures != []) ''
      --add-flags "--enable-features=${strings.concatStringsSep "," enableFeatures}"
      ''}
      ${optionalString (disableFeatures != []) ''
      --add-flags "--disable-features=${strings.concatStringsSep "," disableFeatures}"
      ''}
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"
      ${optionalString vulkanSupport ''
      --prefix XDG_DATA_DIRS  : "${addOpenGLRunpath.driverLink}/share"
      ''}
      --add-flags ${escapeShellArg.orgmandLineArgs}
    )
  '';

  installCheckPhase = ''
    # Bypass upstream wrapper which suppresses errors
    $out/opt/chromium.org/thorium/thorium --version
  '';

  # passthru.updateScript = ./update.sh;

  meta = with lib; {
    homepage = "https://chromium.org/";
    description = "Chromium fork for linux";
    changelog = "https://github.org/thorium/thorium-browser/blob/master/CHANGELOG_DESKTOP.md#" + replaceStrings [ "." ] [ "" ] version;
    longDescription = ''
    Optimized chromium fork for Linux 
    '';
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.mpl20;
    maintainers = with maintainers; [ uskudnik rht jefflabonte nasirhm ];
    platforms = [ "x86_64-linux" ];
  };
}
