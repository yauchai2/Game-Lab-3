"""Build pixel type from a repeatable intensity/hardness preset.

Licensed bundled typefaces; no official JSR font or original atlas is modified.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
from fontTools.ttLib import TTFont
import hashlib, json
root = Path(__file__).resolve().parents[1]
out = root / 'godot/assets/fonts'
preset = json.loads((out / 'pixel-type-preset.json').read_text())
intensity = preset['pixel_intensity']
hardness = preset['edge_hardness']
if not all(isinstance(v, (int, float)) and 0 <= v <= 10 for v in (intensity, hardness)):
    raise ValueError('Pixel intensity and edge hardness must be between 0 and 10.')
if preset['text_size_percent'] != 100:
    raise ValueError('Text size changes require a UI layout review; this preset keeps 100%.')
# Relative art-direction scale: 3 -> 28 px, 5 -> 24 px, 7 -> 20 px.
glyph_size = round(34 - 2 * intensity)
hard_weight = hardness / 10
def edge_alpha(alpha):
    binary = 255 if alpha >= 128 else 0
    return round(hard_weight * binary + (1 - hard_weight) * alpha)
profiles = [('RadioSubtleDisplay', 'BarlowCondensed-BlackItalic.ttf', glyph_size),
            ('RadioSubtleBody', 'DejaVuSansCondensed-Bold.ttf', glyph_size),
            ('RadioPixelChinese', 'AfterhoursUIHK.otf', glyph_size)]
manifest = []
for name, source, size in profiles:
    face = ImageFont.truetype(str(out / source), size)
    atlas = Image.new('RGBA', (1024, 512))
    chinese = name == 'RadioPixelChinese'
    chars = []; x = y = 4; row = size + (8 if chinese else 16)
    if chinese:
        with TTFont(out / source) as source_font:
            codes = sorted(code for code in source_font.getBestCmap() if code >= 128)
    else:
        codes = list(range(32, 127)) + [8734, 8592, 8594, 8593, 8595, 183, 8212, 8211]
    for code in codes:
        char = chr(code); box = face.getbbox(char, anchor='ls')
        width = max(1, box[2] - box[0]); height = max(1, box[3] - box[1])
        if x + width + 4 >= atlas.width:
            x = 4; y += row
        while y + height + 4 >= atlas.height:
            expanded = Image.new('RGBA', (atlas.width, atlas.height * 2))
            expanded.paste(atlas, (0, 0)); atlas = expanded
        mask = Image.new('L', (width, height))
        ImageDraw.Draw(mask).text((-box[0], -box[1]), char, font=face, anchor='ls', fill=255)
        # A neutral cutoff keeps crisp steps without the old >=96 stroke expansion.
        mask = mask.point(edge_alpha)
        glyph = Image.new('RGBA', mask.size, 'white'); glyph.putalpha(mask)
        atlas.paste(glyph, (x, y))
        advance = max(1, round(face.getlength(char))) + (1 if "Display" in name and code != 32 else 0)
        chars.append(f'char id={code} x={x} y={y} width={width} height={height} xoffset={box[0]} yoffset={box[1]+size} xadvance={advance} page=0 chnl=15')
        x += width + 4
    target = out / (name + '.png'); atlas.save(target)
    (out / (name + '.fnt')).write_text(
        f'info face="Afterhours {name}" size={size} bold={0 if chinese else 1} italic={int("Display" in name)} charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=1,1\n'
        f'common lineHeight={size+6} base={size} scaleW={atlas.width} scaleH={atlas.height} pages=1 packed=0\n'
        f'page id=0 file="{name}.png"\nchars count={len(chars)}\n' + '\n'.join(chars) + '\n')
    manifest.append({'font': name, 'source': source, 'glyph_size': size,
                     'preset': preset, 'alpha_levels': sorted(set(atlas.getchannel('A').get_flattened_data())),
                     'display_tracking': int('Display' in name), 'characters': len(chars),
                     'source_sha256': hashlib.sha256((out/source).read_bytes()).hexdigest(),
                     'atlas_sha256': hashlib.sha256(target.read_bytes()).hexdigest()})
(out / 'subtle-pixel-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
