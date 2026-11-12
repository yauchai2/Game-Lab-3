#!/usr/bin/env python3
"""Bakes godot/assets/vfx/*.png from CC0 sources (see godot/assets/vfx/SOURCES.md) into the
game's hard-edged pixel-cel look: 1-bit alpha, flat tones, baked 1px ink outline, low resolution
(drawn with nearest filtering at about 1 texel per 640x360 game pixel).

Usage: build_vfx_sheets.py <hit_sheet_4096.png> <kenney_white_puff_dir> <slash_sheet.png> <out_dir>
  hit sheet   = Sinestesia "Hit Animation | Frame by frame" (hit - yellow.png)   CC0
  puffs       = Kenney "Smoke particle assets" / White puff                       CC0
  slash sheet = tbbk "Pixel art sword slash effect" (192x141, 3x3 of 64x47)       CC0
Outputs (all white where tinted, RGB is a grey level the game multiplies by a colour):
  hit_spark_{tint,core,ink}.png  4x4 cells of 96px (frames 7-13 used in game)
  puffs.png                      3x2 cells of 48px; grey bands = flat cel shading, darkest = ink rim
  slash_{tint,core,ink}.png      3x3 cells of 64x47 -> padded to 66x49 cells
"""
import sys, os
from PIL import Image
import numpy as np

def dilate(mask, r=1):
    out = mask.copy()
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if dx * dx + dy * dy <= r * r + 1:
                out |= np.roll(np.roll(mask, dy, 0), dx, 1)
    return out

def png(mask_or_rgba, path):
    Image.fromarray(mask_or_rgba).save(path)

def layer(mask):
    a = np.zeros(mask.shape + (4,), np.uint8)
    a[..., :3] = 255
    a[..., 3] = mask.astype(np.uint8) * 255
    return a

hit_src, puff_dir, slash_src, out = sys.argv[1:5]
os.makedirs(out, exist_ok=True)

# ---- hit spark -------------------------------------------------------------------------
sheet = Image.open(hit_src).convert("RGBA")
CELL, OUT, HALF = 1024, 96, 330
frames = [np.asarray(sheet.crop(((i % 4) * CELL, (i // 4) * CELL, (i % 4 + 1) * CELL, (i // 4 + 1) * CELL))).astype(np.float32) / 255 for i in range(16)]
best = max(range(16), key=lambda i: frames[i][..., 3].sum())
a = frames[best][..., 3]
ys, xs = np.mgrid[0:CELL, 0:CELL]
cx = (a * xs).sum() / a.sum(); cy = (a * ys).sum() / a.sum()
sheets = {k: np.zeros((OUT * 4, OUT * 4, 4), np.uint8) for k in ("tint", "core", "ink")}
for i, f in enumerate(frames):
    def cell(arr2d):
        im = Image.fromarray((arr2d * 255).astype(np.uint8)).crop((int(cx - HALF), int(cy - HALF), int(cx + HALF), int(cy + HALF)))
        return np.asarray(im.resize((OUT, OUT), Image.BOX)).astype(np.float32) / 255
    body = cell(np.clip((f[..., 3] - 0.10) / 0.25, 0, 1)) >= 0.16
    hot = (cell(np.clip((f[..., 2] - 0.30) / 0.4, 0, 1) * (f[..., 3] > 0.5)) >= 0.35) & body
    x0, y0 = (i % 4) * OUT, (i // 4) * OUT
    sheets["tint"][y0:y0 + OUT, x0:x0 + OUT] = layer(body)
    sheets["core"][y0:y0 + OUT, x0:x0 + OUT] = layer(hot)
    sheets["ink"][y0:y0 + OUT, x0:x0 + OUT] = layer(dilate(body, 1))
for k, v in sheets.items():
    png(v, os.path.join(out, f"hit_spark_{k}.png"))

# ---- dust puffs: flat 3-tone cel with ink rim ---------------------------------------------
P = 48
puffs = np.zeros((P * 2, P * 3, 4), np.uint8)
for n, idx in enumerate([0, 3, 6, 9, 14, 18]):
    im = Image.open(os.path.join(puff_dir, "whitePuff%02d.png" % idx)).convert("RGBA")
    im.thumbnail((P - 2, P - 2), Image.BOX)
    cellimg = Image.new("RGBA", (P, P), (0, 0, 0, 0))
    cellimg.paste(im, ((P - im.width) // 2, (P - im.height) // 2))
    arr = np.asarray(cellimg).astype(np.float32) / 255
    body = arr[..., 3] >= 0.5
    inner = ~dilate(~body, 2) & body        # eroded body
    rim = body & ~inner                      # 2px outer ring -> darkest tone
    lum = arr[..., 0] * 0.5 + arr[..., 1] * 0.3 + arr[..., 2] * 0.2
    tone = np.where(lum > 0.93, 1.0, np.where(lum > 0.80, 0.78, 0.60))
    # light comes from the upper-left: bias the shade band toward the lower-right
    yy, xx = np.mgrid[0:P, 0:P]
    tone = np.where(((xx - P / 2) + (yy - P / 2)) > 6, np.minimum(tone, 0.78), tone)
    tone = np.where(rim, 0.30, tone)
    rgba = np.zeros((P, P, 4), np.uint8)
    rgba[..., :3] = (tone * 255).astype(np.uint8)[..., None]
    rgba[..., 3] = body.astype(np.uint8) * 255
    puffs[(n // 3) * P:(n // 3 + 1) * P, (n % 3) * P:(n % 3 + 1) * P] = rgba
png(puffs, os.path.join(out, "puffs.png"))

# ---- slash arcs (already pixel art) -------------------------------------------------------
src = np.asarray(Image.open(slash_src).convert("RGBA"))
W, H, PAD = 64, 47, 1
CW, CH = W + PAD * 2, H + PAD * 2
sl = {k: np.zeros((CH * 3, CW * 3, 4), np.uint8) for k in ("tint", "core", "ink")}
for i in range(9):
    c = src[(i // 3) * H:(i // 3 + 1) * H, (i % 3) * W:(i % 3 + 1) * W]
    body = np.zeros((CH, CW), bool); body[PAD:PAD + H, PAD:PAD + W] = c[..., 3] > 127
    hot = np.zeros((CH, CW), bool); hot[PAD:PAD + H, PAD:PAD + W] = (c[..., 3] > 127) & (c[..., :3].min(axis=2) > 235)
    x0, y0 = (i % 3) * CW, (i // 3) * CH
    sl["tint"][y0:y0 + CH, x0:x0 + CW] = layer(body)
    sl["core"][y0:y0 + CH, x0:x0 + CW] = layer(hot)
    sl["ink"][y0:y0 + CH, x0:x0 + CW] = layer(dilate(body, 1))
for k, v in sl.items():
    png(v, os.path.join(out, f"slash_{k}.png"))
print("ok", cx, cy)
