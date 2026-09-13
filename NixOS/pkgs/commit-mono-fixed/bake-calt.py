#!/usr/bin/env python3
"""Fold ss01/ss02 into `calt` so the ligatures are on by default.

Both stylistic sets ship off in the released fonts, which is why a stock
install shows no arrows. `calt` is enabled by every shaper, so merging the
lookups into it makes the ligatures work everywhere instead of per-app.

Mirrors what commitmono.com's customiser does with its "download features".
"""
import glob
import os
import sys

from fontTools.ttLib import TTFont

BAKE = ("ss01", "ss02")


def process(path):
    name = os.path.basename(path)
    font = TTFont(path)
    if "GSUB" not in font:
        print("%s: no GSUB, skipping" % name)
        return

    records = font["GSUB"].table.FeatureList.FeatureRecord
    calt = next((r for r in records if r.FeatureTag == "calt"), None)
    if calt is None:
        # Nothing to merge into; ligatures stay opt-in rather than mangling the
        # feature list order.
        print("%s: no calt feature, leaving %s opt-in" % (name, "/".join(BAKE)))
        return

    extra = []
    for rec in records:
        if rec.FeatureTag in BAKE:
            extra.extend(rec.Feature.LookupListIndex)

    if not extra:
        print("%s: no %s lookups found" % (name, "/".join(BAKE)))
        return

    before = list(calt.Feature.LookupListIndex)
    calt.Feature.LookupListIndex = sorted(set(before) | set(extra))
    font.save(path)
    print("%s: calt lookups %d -> %d (+%s)" % (
        name, len(before), len(calt.Feature.LookupListIndex), "/".join(BAKE)))


def main():
    target = sys.argv[1]
    paths = sorted(glob.glob(os.path.join(target, "*.ttf")))
    if not paths:
        raise SystemExit("no ttf files in %s" % target)
    for p in paths:
        process(p)


if __name__ == "__main__":
    main()
