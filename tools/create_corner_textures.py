# Original deterministic low-resolution multipliers; requires Pillow.
from pathlib import Path
from PIL import Image
import random
root=Path(__file__).resolve().parents[1]/'godot/assets/textures'
root.mkdir(parents=True,exist_ok=True)
r=random.Random(20261108)
# Deliberate indexed-value multipliers. Broad chipped paint, not photoreal noise.
im=Image.new('RGB',(128,128));px=im.load()
for y in range(128):
 for x in range(128):
  coarse=((x//9)*17+(y//13)*11)%23
  value=245 if coarse<15 else 232
  if r.random()<0.07:value=220
  px[x,y]=(value,value,min(255,value+2))
for i in range(18):
 x=r.randrange(128);y=r.randrange(128);w=r.randrange(2,8);h=r.randrange(4,22)
 for yy in range(y,min(128,y+h)):
  for xx in range(x,min(128,x+w)):
   if (xx-x)+(yy-y)//4<w+2:px[xx,yy]=(208,211,211)
im.save(root/'corner_plaster_128.png')
im=Image.new('RGB',(128,128));px=im.load()
for y in range(128):
 for x in range(128):
  tx=x//24;ty=y//16
  value=([247,233,240,226][(tx+ty*3)%4])
  if x%24<2 or y%16<2:value=160
  if x%24==2 or y%16==2:value=252
  px[x,y]=(value,value,min(255,value+3))
im.save(root/'corner_tiles_128.png')
im=Image.new('RGB',(128,128));px=im.load()
for y in range(128):
 for x in range(128):
  value=[212,229,245,245,237,222,203,221][y%8]
  if y//8 in [3,11] and x%37<3:value-=21
  px[x,y]=(value,value,min(255,value+4))
im.save(root/'corner_shutter_128.png')
