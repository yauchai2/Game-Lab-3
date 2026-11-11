"""User-authorized image cropping from the three approved UI designs; no redraw.
Regenerates original-byte title/roster plus fixed headset, pause and ribbon crops.
"""
from pathlib import Path
from PIL import Image,ImageDraw
import shutil,json,hashlib
root=Path(__file__).resolve().parents[1];src=root/'references/ui-jsr-2026-11-09/generated';out=root/'godot/assets/ui/replica';out.mkdir(parents=True,exist_ok=True)
shutil.copy2(src/'01-main-menu-direction.png',out/'title.png')
shutil.copy2(src/'03-roster-direction.png',out/'roster-reference.png')
r=Image.open(src/'03-roster-direction.png').convert('RGBA');h=Image.open(src/'02-hud-direction.png').convert('RGBA')
records=[]
def crop(image,name,box,poly=None):
 p=out/(name+'.png');im=image.crop(box)
 if poly:
  mask=Image.new('L',im.size,0);ImageDraw.Draw(mask).polygon([(x-box[0],y-box[1]) for x,y in poly],fill=255);im.putalpha(mask)
 im.save(p);records.append({'file':str(p.relative_to(root)),'source_box':box,'polygon':poly,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
crop(h,'pause',(1490,111,1648,161),[(1505,116),(1646,111),(1631,150),(1490,161)])
crop(h,'headphones',(75,18,150,98),[(113,19),(135,27),(149,47),(149,69),(134,90),(111,98),(88,87),(76,65),(78,42),(92,25)])
crop(h,'controls',(359,855,1312,913),[(360,872),(396,855),(1304,855),(1270,902),(382,913)])
(root/'references/ui-replica-2026-11-09/crops.json').write_text(json.dumps({'method':'User explicitly authorized cropping; PIL crop/polygon alpha only, no invented character art.','entries':records},indent=2)+'\n')
