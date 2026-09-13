{
  lib,
  stdenvNoCC,
  python3,
  commit-mono,
  nerd-font-patcher,
  # Merge ss01+ss02 into `calt` so arrows and comparisons ligate in every app.
  # Set false to keep them opt-in (kitty: font_features "CommitMonoFixed Nerd Font Mono" +ss01 +ss02).
  bakeLigatures ? true,
}:

# Commit Mono as it should have shipped: upstream's ttfautohint TTFs (the only
# hinted build that exists) with the descender clipping fixed, Nerd Font glyphs
# patched in, and the ligature sets on by default.
let
  python = python3.withPackages (ps: [ ps.fonttools ]);
in
stdenvNoCC.mkDerivation {
  pname = "commit-mono-fixed";
  inherit (commit-mono) version;

  dontUnpack = true;
  nativeBuildInputs = [ python nerd-font-patcher ];

  buildPhase = ''
    runHook preBuild

    mkdir -p work patched
    # `cp` keeps the store's read-only mode, and fontTools rewrites in place.
    cp ${commit-mono}/share/fonts/truetype/*.ttf work/
    chmod u+w work/*.ttf

    python3 ${./retune.py} work

    for font in work/*.ttf; do
      # No --mono: it scales the added glyphs down to fit one cell, which makes
      # icons ~2/3 cap height. The default keeps natural size at a 1-cell
      # advance -- byte-identical sizing to Maple Mono NF.
      nerd-font-patcher --complete --outputdir patched "$font"
    done

    ${lib.optionalString bakeLigatures "python3 ${./bake-calt.py} patched"}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/fonts/truetype
    install -m644 patched/*.ttf $out/share/fonts/truetype/
    runHook postInstall
  '';

  meta = {
    description = "Commit Mono with unclipped metrics, Nerd Font glyphs and default-on ligatures";
    homepage = "https://commitmono.com/";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
}
