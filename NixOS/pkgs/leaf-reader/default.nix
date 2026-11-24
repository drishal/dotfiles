# Upstream's prebuilt release, not the flake source: buildRustPackage runs its
# suite, and doc::tests::watched_files_settle_and_failed_reads_retry races a
# 250ms wall clock (src/doc.rs:268), so a loaded builder fails it. Release
# tarballs are per-target and already stripped; bump version + hash together.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  alsa-lib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "leaf";
  version = "0.18.0";

  src = fetchurl {
    url = "https://github.com/DeepanshuMishraa/leaf/releases/download/v${finalAttrs.version}/leaf-x86_64-unknown-linux-gnu.tar.gz";
    hash = "sha256-BGRDyndoVoddWa5zOnos6TM/mlp8VXEJEUdBQ0krQa8=";
  };

  # Tarball has leaf, README.md and LICENSE at its root, no top-level dir.
  sourceRoot = ".";

  nativeBuildInputs = [ autoPatchelfHook ];
  # libasound.so.2 is the only NEEDED the loader can't find on NixOS; libgcc_s
  # must be pinned too so the RPATH doesn't rely on the host's loader cache.
  buildInputs = [
    alsa-lib
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    install -Dm755 leaf $out/bin/leaf
    install -Dm644 README.md LICENSE -t $out/share/doc/${finalAttrs.pname}
  '';

  meta = {
    description = "Read PDFs, markdown files and web articles in the terminal";
    homepage = "https://github.com/DeepanshuMishraa/leaf";
    license = lib.licenses.mit;
    mainProgram = "leaf";
    platforms = [ "x86_64-linux" ];
  };
})
