#!/usr/bin/env python3
"""Retune Commit Mono's vertical metrics so descenders stop being clipped.

Upstream declares ascent/descent 900/-200 while its own g/j reach -210, so a
terminal that sizes the cell from those metrics shears the bottom off. The
official customiser's "line height 1.10" adds the same 50 units top and bottom.
"""
import glob
import os
import sys

from fontTools.ttLib import TTFont

ASCENDER, DESCENDER = 950, -250
FAMILY_FROM, FAMILY_TO = "CommitMono", "CommitMonoFixed"
NAME_IDS = {1, 2, 3, 4, 6, 16, 17, 21, 22}


def process(path):
    font = TTFont(path)
    hhea, os2 = font["hhea"], font["OS/2"]

    hhea.ascender, hhea.descender, hhea.lineGap = ASCENDER, DESCENDER, 0
    os2.sTypoAscender, os2.sTypoDescender, os2.sTypoLineGap = ASCENDER, DESCENDER, 0
    os2.usWinAscent, os2.usWinDescent = ASCENDER, -DESCENDER
    os2.fsSelection |= 1 << 7  # USE_TYPO_METRICS

    # Distinct family name so this can sit alongside nerd-fonts.commit-mono.
    for rec in font["name"].names:
        if rec.nameID not in NAME_IDS:
            continue
        try:
            text = rec.toUnicode()
        except Exception:
            continue
        if FAMILY_FROM in text:
            rec.string = text.replace(FAMILY_FROM, FAMILY_TO)

    font.recalcBBoxes = True
    font.save(path)
    print("retuned %s -> asc %d desc %d" % (os.path.basename(path), ASCENDER, DESCENDER))


def main():
    target = sys.argv[1]
    paths = sorted(glob.glob(os.path.join(target, "*.ttf")))
    if not paths:
        raise SystemExit("no ttf files in %s" % target)
    for p in paths:
        process(p)


if __name__ == "__main__":
    main()
