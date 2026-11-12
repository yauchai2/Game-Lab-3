#!/usr/bin/env python3
"""Subset Noto Sans HK Bold (SIL OFL 1.1) to the glyphs the story opening subtitles use.

The repo's AfterhoursUIHK subset comes from a Debian package that is not always
installed, so the opening keeps its own small, reproducible subtitle face.
Source: https://raw.githubusercontent.com/notofonts/noto-cjk/main/Sans/SubsetOTF/HK/NotoSansHK-Bold.otf
Run again after editing the subtitle lines:
    python3 tools/subset_story_opening_font.py /path/to/NotoSansHK-Bold.otf
"""
from pathlib import Path
import hashlib, json, sys
from fontTools.ttLib import TTFont
from fontTools import subset

root = Path(__file__).resolve().parents[1]
source = Path(sys.argv[1])
script = (root / "godot/scripts/combat/cinematic/story_opening.gd").read_text()
text = "".join(sorted({c for c in script if ord(c) > 0x2000})) + "".join(chr(i) for i in range(32, 127))
font = TTFont(source, recalcTimestamp=False)
options = subset.Options()
options.name_IDs = ["*"]; options.name_legacy = True; options.name_languages = ["*"]
subsetter = subset.Subsetter(options=options); subsetter.populate(text=text); subsetter.subset(font)
for record in font["name"].names:
    if record.nameID in (1, 4, 6, 16):
        record.string = ("Afterhours Story HK" if record.nameID != 6 else "AfterhoursStoryHK").encode(record.getEncoding(), errors="replace")
output = root / "godot/assets/fonts/StoryOpeningHK.otf"
font.save(output)
manifest = {
    "source": "https://github.com/notofonts/noto-cjk (Sans/SubsetOTF/HK/NotoSansHK-Bold.otf)",
    "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
    "license": "SIL OFL 1.1",
    "derivative_family": "Afterhours Story HK",
    "generator": "tools/subset_story_opening_font.py",
    "output": "godot/assets/fonts/StoryOpeningHK.otf",
    "output_sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
    "non_ascii_characters": "".join(c for c in text if ord(c) > 0x2000),
    "bytes": output.stat().st_size,
}
(root / "references/ui-fonts/story-opening-subset.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
print(json.dumps(manifest, ensure_ascii=False))
