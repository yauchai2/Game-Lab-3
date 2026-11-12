#!/usr/bin/env python3
"""Builds godot/assets/vfx/*.png from CC0 sources (see godot/assets/vfx/SOURCES.md).
Usage: build_vfx_sheets.py <hit_sheet_4096.png> <kenney_white_puff_dir> <out_dir>
hit sheet = Sinestesia "Hit Animation | Frame by frame" (hit - yellow.png), CC0.
Note: frames 0-5 of the source contain a smooth shockwave ring; the game plays frames 6-13 only.
Output: hit_spark_tint.png / hit_spark_core.png (4x4, 256px cells, white+alpha, tint at draw time)
        puffs.png (3x2, 128px cells, white+alpha).
"""
import sys, glob, os
from PIL import Image
import numpy as np
src, puff_dir, out = sys.argv[1:4]
os.makedirs(out, exist_ok=True)
sheet = Image.open(src).convert("RGBA")
CELL = 1024
OUT = 256
frames = []
for i in range(16):
    c = sheet.crop(((i % 4) * CELL, (i // 4) * CELL, (i % 4 + 1) * CELL, (i // 4 + 1) * CELL))
    frames.append(np.asarray(c).astype(np.float32) / 255.0)
# Shared pivot = alpha-weighted centroid of the brightest frame so the burst stays put.
best = max(range(16), key=lambda i: frames[i][..., 3].sum())
a = frames[best][..., 3]
ys, xs = np.mgrid[0:CELL, 0:CELL]
cx = (a * xs).sum() / a.sum(); cy = (a * ys).sum() / a.sum()
tint = Image.new("RGBA", (OUT * 4, OUT * 4), (255, 255, 255, 0))
core = Image.new("RGBA", (OUT * 4, OUT * 4), (255, 255, 255, 0))
half = 360  # source px around the pivot that map to one 256 cell
for i, f in enumerate(frames):
    alpha = f[..., 3]
    # Harden the glow so it reads as an ink-style cel instead of a soft bloom.
    hard = np.clip((alpha - 0.18) / 0.45, 0, 1)
    lum = f[..., 2]  # blue channel is high only in the white-hot core of the yellow art
    hot = np.clip((lum - 0.35) / 0.4, 0, 1) * hard
    for name, layer, target in (("t", hard, tint), ("c", hot, core)):
        rgba = np.zeros((CELL, CELL, 4), np.float32); rgba[..., :3] = 1; rgba[..., 3] = layer
        im = Image.fromarray((rgba * 255).astype(np.uint8))
        im = im.crop((int(cx - half), int(cy - half), int(cx + half), int(cy + half))).resize((OUT, OUT), Image.LANCZOS)
        target.paste(im, ((i % 4) * OUT, (i // 4) * OUT))
tint.save(os.path.join(out, "hit_spark_tint.png")); core.save(os.path.join(out, "hit_spark_core.png"))
pick = [0, 3, 6, 9, 14, 18]
puffs = Image.new("RGBA", (128 * 3, 128 * 2), (255, 255, 255, 0))
for n, idx in enumerate(pick):
    im = Image.open(os.path.join(puff_dir, "whitePuff%02d.png" % idx)).convert("RGBA")
    im.thumbnail((124, 124), Image.LANCZOS)
    cell = Image.new("RGBA", (128, 128), (255, 255, 255, 0))
    cell.paste(im, ((128 - im.width) // 2, (128 - im.height) // 2))
    arr = np.asarray(cell).copy(); arr[..., :3] = 255  # white; shade comes from tint
    puffs.paste(Image.fromarray(arr), ((n % 3) * 128, (n // 3) * 128))
puffs.save(os.path.join(out, "puffs.png"))
print("pivot", cx, cy, "best", best)
