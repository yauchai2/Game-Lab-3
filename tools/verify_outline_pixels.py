"""Check an outline screenshot pair and verify the primary sign remains readable."""
from pathlib import Path
import json
import numpy as np
from PIL import Image

base = Path(__file__).resolve().parents[1] / 'docs/evidence/outline'
a = np.asarray(Image.open(base/'01_off.png').convert('RGB'), dtype=np.int16)
b = np.asarray(Image.open(base/'02_on.png').convert('RGB'), dtype=np.int16)
if a.shape != b.shape or a.shape[:2] != (720, 1280):
    raise SystemExit('Capture dimensions do not match 1280x720.')
difference = np.abs(a-b).max(axis=2)
changed = int((difference > 8).sum())
# Fixed primary-sign crop for this camera; label remains gold after the post-process.
def gold_pixels(image):
    crop = image[275:414,527:572]
    return int(((crop[:,:,0] > 160) & (crop[:,:,1] > 100) & (crop[:,:,2] < 155)).sum())
original_gold = gold_pixels(a)
outlined_gold = gold_pixels(b)
ratio = outlined_gold/max(original_gold,1)
checks = {'outline_changes_some_pixels':changed > 2000,
          'outline_does_not_cover_the_majority':changed < a.shape[0]*a.shape[1]*.15,
          'gold_sign_remains_visible':original_gold > 100 and ratio > .90}
report = {'passed':all(checks.values()),'checks':checks,'changed_pixels_over_8':changed,
          'gold_pixels_before':original_gold,'gold_pixels_after':outlined_gold,'gold_retention_ratio':ratio,
          'scope':'same fixed 1280x720 entry view, Godot Compatibility / Mesa llvmpipe; not a hardware GPU or all-camera guarantee'}
(base/'pixel_comparison.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report))
raise SystemExit(0 if report['passed'] else 1)
