"""Check captured Godot sky across one wrap; requires Pillow and NumPy."""
from pathlib import Path
import json
import numpy as np
from PIL import Image, ImageDraw

base = Path(__file__).resolve().parents[1] / 'docs/evidence/sky-rotation'
def rgb(name):
    return np.asarray(Image.open(base / name).convert('RGB'))

def mismatch(a, b):
    return float(np.any(a != b, axis=2).mean())

a0, a360 = rgb('yaw_000.png'), rgb('yaw_360.png')
a180, aminus180 = rgb('yaw_180.png'), rgb('yaw_minus180.png')
left, right = rgb('yaw_179_75.png'), rgb('yaw_minus179_75.png')
# At 640 px and 60-degree FOV, a 0.5-degree yaw is about 4.84 px.
# Compare the overlapping central area with a 5 px horizontal registration.
a = left[160:440, 200:440]
b = right[160:440, 195:435]
aligned = mismatch(a, b)
unregistered = mismatch(a, right[160:440, 200:440])
white_cloud = float(((a[:, :, 0] > 230) & (a[:, :, 1] > 230)).mean())
checks = {
    'full_rotation_same_view': mismatch(a0, a360) < 0.001,
    'opposite_wrap_same_view': mismatch(a180, aminus180) < 0.001,
    'test_area_contains_cloud': white_cloud > 0.03,
    'across_wrap_registered_mismatch_under_1_percent': aligned < 0.01,
    'registration_improves_match': aligned < unregistered,
}
report = {'passed': all(checks.values()), 'checks': checks, 'registered_mismatch_fraction': aligned,
          'unregistered_mismatch_fraction': unregistered, 'cloud_fraction': white_cloud,
          'registration_pixels': -5, 'capture_resolution': [640, 640], 'fov_degrees': 60,
          'renderer': 'Godot Compatibility / Mesa llvmpipe',
          'scope': 'specific sky-only camera positions and one azimuth wrap; not real hardware or human playtest'}
(base / 'pixel-verification.json').write_text(json.dumps(report, indent=2) + '\n')
contact = Image.new('RGB', (1280, 680), '#101820')
draw = ImageDraw.Draw(contact)
for i in range(8):
    angle = i * 45
    thumb = Image.open(base / f'yaw_{angle:03}.png').convert('RGB').resize((320, 320))
    x, y = (i % 4) * 320, (i // 4) * 340
    contact.paste(thumb, (x, y))
    draw.text((x+8, y+323), f'{angle} degrees', fill='white')
contact.save(base / 'rotation-contact.png')
print(json.dumps(report, ensure_ascii=False))
raise SystemExit(0 if report['passed'] else 1)
