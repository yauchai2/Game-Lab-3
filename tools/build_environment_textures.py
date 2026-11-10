"""Build small original repeatable texture maps for the street prototype.

The textures are neutral multipliers, so Godot material colors remain editable.
Requires Pillow and NumPy. No reference image pixels are used.
"""
from pathlib import Path
import math
import numpy as np
from PIL import Image

OUT = Path(__file__).resolve().parents[1] / 'godot/assets/textures'
OUT.mkdir(parents=True, exist_ok=True)
SIZE = 128
rng = np.random.default_rng(31957)
y, x = np.mgrid[0:SIZE, 0:SIZE]

def periodic_noise(seed):
    random = np.random.default_rng(seed)
    values = np.zeros((SIZE, SIZE), dtype=np.float64)
    for frequency, amplitude in [(1, 2.0), (2, 1.5), (4, 1.0), (8, .55), (16, .3)]:
        for _ in range(3):
            fx = int(random.integers(-frequency, frequency+1))
            fy = int(random.integers(-frequency, frequency+1))
            phase = random.uniform(0, math.tau)
            values += amplitude * np.cos(math.tau*(fx*x+fy*y)/SIZE+phase)
    return values

def save(name, values):
    a = np.clip(np.rint(values),0,255).astype(np.uint8)
    if a.ndim == 2:
        a = np.repeat(a[:,:,None],3,axis=2)
    Image.fromarray(a,'RGB').save(OUT/name, optimize=True)
    print(name, f'{SIZE}x{SIZE}', 'min',int(a.min()),'max',int(a.max()))

# A low-contrast concrete aggregate; periodic signals avoid a hard image seam.
road = 242 + periodic_noise(11) + rng.normal(0,1.2,(SIZE,SIZE))
for _ in range(90):
    cx, cy = rng.integers(0,SIZE,2)
    radius = int(rng.integers(1,4))
    dx = np.minimum(np.abs(x-cx),SIZE-np.abs(x-cx))
    dy = np.minimum(np.abs(y-cy),SIZE-np.abs(y-cy))
    road[(dx*dx+dy*dy) < radius*radius] -= rng.uniform(2,6)
save('road_asphalt_128.png',road)

# 32 px modular sidewalk slabs, with quiet color changes and narrow grout.
tiles = np.full((SIZE,SIZE),242.0)
for row in range(4):
    for col in range(4):
        variation = rng.uniform(-3.5,3.5)
        tiles[row*32:(row+1)*32,col*32:(col+1)*32] += variation
tiles += periodic_noise(15)*.35
tiles[(x%32==0)|(y%32==0)] -= 18
tiles[(x%32==1)|(y%32==1)] -= 4
save('sidewalk_tiles_128.png',tiles)

# Soft cement panels: restrained seams and wear under broad existing color blocks.
wall = 245 + periodic_noise(25)*.65 + rng.normal(0,.8,(SIZE,SIZE))
wall[(x%64==0)|(y%64==0)] -= 9
wall[(x%64==1)|(y%64==1)] -= 2
for _ in range(32):
    cx, cy = rng.integers(0,SIZE,2)
    wall[cy:cy+min(3,SIZE-cy),cx:cx+min(2,SIZE-cx)] -= rng.uniform(2,6)
save('painted_concrete_128.png',wall)
