"""Deterministic original pixel tiles: broad paint marks, no per-pixel noise."""
from pathlib import Path
from PIL import Image, ImageDraw
import hashlib,json
out=Path('godot/assets/textures/radio');out.mkdir(exist_ok=True)
for name,base,patch,line in [('asphalt','c9c6be','bdbab1','a9aaa3'),('concrete','fff9e7','e9e4d3','d9d3c3'),('paving','e3dec9','d4ceba','aaa997')]:
 im=Image.new('RGB',(128,128),'#'+base);d=ImageDraw.Draw(im)
 if name=='paving':
  for y in [0,32,64,96]:
   d.line([(0,y),(127,y+1)],fill='#'+line,width=2)
   for x in [0,64,128]:d.line([(x+(16 if y%64 else 0),y),(x+(15 if y%64 else 1),y+31)],fill='#'+line,width=2)
 for x,y in [(9,17),(78,9),(44,69),(105,92)]:
  d.polygon([(x,y),(x+13,y-2),(x+19,y+4),(x+9,y+9),(x-2,y+6)],fill='#'+patch)
 if name=='asphalt':
  d.line([(17,100),(23,93),(22,85),(30,79)],fill='#'+line,width=1)
  d.line([(23,93),(35,97),(41,96)],fill='#'+line,width=1)
 elif name=='concrete':
  d.line([(91,41),(89,52),(92,61)],fill='#'+line,width=2)
 im.save(out/(name+'.png'))
Path('references/unified-pixel-2026-11-10/street-tiles.json').write_text(json.dumps({'method':'Original deterministic 128px opaque pixel polygons and strokes; authored generator, no photograph or generative image','files':{str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in out.glob('*.png')}},indent=2))
