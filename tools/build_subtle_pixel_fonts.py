"""Build crisp pixel type: 20 px glyphs, binary alpha and clear letter gaps.

Licensed bundled typefaces; no official JSR font or original atlas is modified.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import hashlib, json
root = Path(__file__).resolve().parents[1]
out = root / 'godot/assets/fonts'
profiles = [('RadioSubtleDisplay', 'BarlowCondensed-BlackItalic.ttf', 20),
            ('RadioSubtleBody', 'DejaVuSansCondensed-Bold.ttf', 20)]
manifest = []
for name, source, size in profiles:
    face = ImageFont.truetype(str(out / source), size)
    atlas = Image.new('RGBA', (1024, 512))
    chars = []; x = y = 4; row = size + 16
    for code in list(range(32, 127)) + [8734, 8592, 8594, 8593, 8595, 183, 8212, 8211]:
        char = chr(code); box = face.getbbox(char, anchor='ls')
        width = max(1, box[2] - box[0]); height = max(1, box[3] - box[1])
        if x + width + 4 >= atlas.width:
            x = 4; y += row
        assert y + height < atlas.height
        mask = Image.new('L', (width, height))
        ImageDraw.Draw(mask).text((-box[0], -box[1]), char, font=face, anchor='ls', fill=255)
        # A neutral cutoff keeps crisp steps without the old >=96 stroke expansion.
        mask = mask.point(lambda alpha: (255 if alpha >= 128 else 0))
        glyph = Image.new('RGBA', mask.size, 'white'); glyph.putalpha(mask)
        atlas.paste(glyph, (x, y))
        advance = max(1, round(face.getlength(char))) + (1 if "Display" in name and code != 32 else 0)
        chars.append(f'char id={code} x={x} y={y} width={width} height={height} xoffset={box[0]} yoffset={box[1]+size} xadvance={advance} page=0 chnl=15')
        x += width + 4
    target = out / (name + '.png'); atlas.save(target)
    (out / (name + '.fnt')).write_text(
        f'info face="Afterhours {name}" size={size} bold=1 italic={int("Display" in name)} charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=1,1\n'
        f'common lineHeight={size+6} base={size} scaleW=1024 scaleH=512 pages=1 packed=0\n'
        f'page id=0 file="{name}.png"\nchars count={len(chars)}\n' + '\n'.join(chars) + '\n')
    manifest.append({'font': name, 'source': source, 'glyph_size': size,
                     'alpha_levels': [0, 255], 'display_tracking': int('Display' in name), 'characters': len(chars),
                     'source_sha256': hashlib.sha256((out/source).read_bytes()).hexdigest(),
                     'atlas_sha256': hashlib.sha256(target.read_bytes()).hexdigest()})
(out / 'subtle-pixel-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
