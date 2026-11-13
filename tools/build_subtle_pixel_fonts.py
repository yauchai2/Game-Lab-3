"""Build medium pixel type: 24 px glyphs and three alpha levels.

Licensed bundled typefaces; no official JSR font or original atlas is modified.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import hashlib, json
root = Path(__file__).resolve().parents[1]
out = root / 'godot/assets/fonts'
profiles = [('RadioSubtleDisplay', 'BarlowCondensed-BlackItalic.ttf', 24),
            ('RadioSubtleBody', 'DejaVuSansCondensed-Bold.ttf', 24)]
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
        # Preserve tiny counters/letter gaps instead of the old >=96 binary cutoff.
        mask = mask.point(lambda alpha: (0 if alpha < 64 else (128 if alpha < 192 else 255)))
        glyph = Image.new('RGBA', mask.size, 'white'); glyph.putalpha(mask)
        atlas.paste(glyph, (x, y))
        advance = max(1, round(face.getlength(char)))
        chars.append(f'char id={code} x={x} y={y} width={width} height={height} xoffset={box[0]} yoffset={box[1]+size} xadvance={advance} page=0 chnl=15')
        x += width + 4
    target = out / (name + '.png'); atlas.save(target)
    (out / (name + '.fnt')).write_text(
        f'info face="Afterhours {name}" size={size} bold=1 italic={int("Display" in name)} charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=1,1\n'
        f'common lineHeight={size+6} base={size} scaleW=1024 scaleH=512 pages=1 packed=0\n'
        f'page id=0 file="{name}.png"\nchars count={len(chars)}\n' + '\n'.join(chars) + '\n')
    manifest.append({'font': name, 'source': source, 'glyph_size': size,
                     'alpha_levels': [0, 128, 255], 'characters': len(chars),
                     'source_sha256': hashlib.sha256((out/source).read_bytes()).hexdigest(),
                     'atlas_sha256': hashlib.sha256(target.read_bytes()).hexdigest()})
(out / 'subtle-pixel-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
