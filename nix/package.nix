{
  lib,
  rustPlatform,
  pkg-config,
  wrapGAppsHook4,
  makeShellWrapper,
  glib,
  gtk4,
  libadwaita,
  mpv-unwrapped,
  libepoxy,
  openssl,
  nodejs,
  ffmpeg,
}:

let
  cargoToml = lib.importTOML ../Cargo.toml;
in
rustPlatform.buildRustPackage {
  pname = cargoToml.package.name;
  inherit (cargoToml.package) version;

  src = lib.cleanSource ../.;

  cargoLock = {
    lockFile = ../Cargo.lock;
    outputHashes = {
      "libmpv2-5.0.3" = "sha256-Dtg/JgREFO3e8HnULIrVbCQZ3yF4ERL0yJXfToxy5yE=";
      "libmpv2-sys-4.0.1" = "sha256-Dtg/JgREFO3e8HnULIrVbCQZ3yF4ERL0yJXfToxy5yE=";
      "localsearch-0.1.0" = "sha256-wWmusHYmT7wtN+mgGvTMUbp0JXYsbpZRfb5qQfQLdlQ=";
      "stremio-core-0.1.0" = "sha256-RCU9oHBLbeuZk/cx4V17jf3Cx30XS8TMIx9W+WnIoj8=";
      "stremio-derive-0.1.0" = "sha256-RCU9oHBLbeuZk/cx4V17jf3Cx30XS8TMIx9W+WnIoj8=";
      "stremio-watched-bitfield-0.1.0" = "sha256-RCU9oHBLbeuZk/cx4V17jf3Cx30XS8TMIx9W+WnIoj8=";
    };
  };

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook4
    glib # glib-compile-schemas
    makeShellWrapper
  ];

  buildInputs = [
    glib
    gtk4
    libadwaita
    mpv-unwrapped
    libepoxy
    openssl
  ];

  postInstall = ''
    install -Dm644 data/xyz.timtimtim.Losange.gschema.xml \
      -t $out/share/glib-2.0/schemas
    glib-compile-schemas $out/share/glib-2.0/schemas

    install -Dm644 data/icons/xyz.timtimtim.Losange.svg \
      -t $out/share/icons/hicolor/scalable/apps
    install -Dm644 data/xyz.timtimtim.Losange.metainfo.xml \
      -t $out/share/metainfo
    install -Dm644 data/xyz.timtimtim.Losange.desktop \
      -t $out/share/applications

    substituteInPlace $out/share/applications/xyz.timtimtim.Losange.desktop \
      --replace-fail "/usr/bin/losange" "$out/bin/losange"
  '';

  # The app spawns the Stremio streaming server with node, which in turn uses
  # ffmpeg, and it loads libepoxy with dlopen at runtime.
  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : ${
        lib.makeBinPath [
          nodejs
          ffmpeg
        ]
      }
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libepoxy ]}
      --run 'if [ -e /dev/nvidia0 ]; then export GSK_RENDERER=opengl; fi'
    )
  '';

  dontWrapGApps = true;
  postFixup = ''
    wrapProgram $out/bin/losange "''${gappsWrapperArgs[@]}"
  '';

  meta = {
    description = cargoToml.package.description;
    homepage = cargoToml.package.repository;
    license = lib.licenses.gpl3Only;
    mainProgram = "losange";
    platforms = lib.platforms.linux;
  };
}
