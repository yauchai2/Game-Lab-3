"""Check material comparison and cast-shadow captures; requires Pillow."""
from pathlib import Path
from PIL import Image, ImageChops
import json
root = Path(__file__).resolve().parents[1] / 'docs/evidence/style'
def changed(first, second, threshold=5):
    a = Image.open(root / first).convert('RGB')
    b = Image.open(root / second).convert('RGB')
    if a.size != (800,800) or b.size != a.size:
        raise ValueError('Unexpected capture dimensions')
    r,g,blue = ImageChops.difference(a,b).split()
    maximum = ImageChops.lighter(ImageChops.lighter(r,g),blue)
    return sum(maximum.histogram()[threshold+1:])
entry = changed('02_two_bands.png','03_three_bands.png')
detail = changed('05_two_detail.png','06_three_detail.png')
a = Image.open(root/'02_two_bands.png').convert('RGB')
b = Image.open(root/'04_shadow_off.png').convert('RGB')
orange = 0
for y in range(30,550):
    for x in range(530,799):
        r,g,blue = a.getpixel((x,y)); other = b.getpixel((x,y))
        if r>70 and r>g*1.25 and r>blue*1.3 and max(abs(r-other[0]),abs(g-other[1]),abs(blue-other[2]))>8:
            orange += 1
report = {'entry_changed_pixels_gt5':entry,'detail_changed_pixels_gt5':detail,'orange_facade_shadow_changed_pixels_gt8':orange,'image_size':[800,800],'method':'Godot Compatibility captures; Mesa llvmpipe software rendering; no hardware performance inference'}
(root/'pixel_comparison.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report))
if entry < 1000 or detail < 1000 or orange < 100:
    raise SystemExit('Material or shadow comparison did not produce the expected visible difference')
