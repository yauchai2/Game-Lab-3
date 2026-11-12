#!/usr/bin/env python3
"""Original hand-authored polygon icons. Four readable faces per 3D drum.
The hidden fourth face changes to the selected reward; initial visible faces stay
unchanged, avoiding a texture pop when drawing starts. Does not touch source art.
"""
from pathlib import Path
from PIL import Image,ImageDraw
import hashlib,json
ROOT=Path(__file__).resolve().parents[1];ART=ROOT/'godot/assets/ability_draw';OUT=ART/'pool';OUT.mkdir(parents=True,exist_ok=True)
INK='#141224';PAPER='#d8ead7'
IDS=['speed','guard','charge','fury','plate','flow','eco','breach','siphon']
def shield(d):d.polygon([(17,19),(62,7),(110,19),(104,78),(65,121),(25,83)],fill=INK)
for kind in IDS:
 if kind in IDS[:3]:
  image=Image.open(ART/(kind+'.png')).convert('RGBA')
 else:
  image=Image.new('RGBA',(128,128));d=ImageDraw.Draw(image)
  if kind=='fury':
   d.polygon([(64,7),(76,35),(106,17),(94,49),(122,62),(92,75),(107,109),(76,93),(62,123),(49,94),(18,109),(32,77),(6,64),(35,50),(20,19),(49,35)],fill=INK)
   d.polygon([(64,39),(47,72),(64,66),(58,91),(84,57),(67,61),(76,39)],fill=PAPER)
  elif kind=='plate':
   d.polygon([(28,15),(48,9),(80,9),(101,15),(92,42),(110,60),(102,116),(25,116),(17,60),(35,42)],fill=INK)
   d.polygon([(44,49),(85,49),(79,95),(49,95)],fill=PAPER)
   d.rectangle((54,28,74,39),fill=PAPER)
  elif kind=='flow':
   d.arc((23,22,105,105),205,350,fill=INK,width=17)
   d.polygon([(87,14),(119,34),(91,52)],fill=INK)
   d.arc((23,22,105,105),25,170,fill=INK,width=17)
   d.polygon([(40,114),(8,94),(36,76)],fill=INK)
   d.polygon([(63,43),(49,67),(63,65),(59,86),(79,57),(65,60),(72,43)],fill=INK)
  elif kind=='eco':
   d.rectangle((45,8,83,22),fill=INK)
   d.polygon([(22,22),(106,22),(112,114),(16,114)],fill=INK)
   d.rectangle((31,36,97,99),fill=PAPER)
   d.polygon([(69,40),(43,73),(61,70),(53,96),(89,58),(69,61),(80,40)],fill=INK)
  elif kind=='breach':
   shield(d)
   d.polygon([(66,6),(52,45),(70,59),(46,88),(58,122),(80,81),(65,65),(88,38),(77,7)],fill=PAPER)
   d.polygon([(4,25),(24,37),(19,53)],fill=INK)
   d.polygon([(124,82),(105,75),(101,93)],fill=INK)
  elif kind=='siphon':
   d.polygon([(63,7),(98,56),(112,80),(107,103),(87,119),(43,119),(21,104),(15,81),(29,56)],fill=INK)
   d.rectangle((54,53,75,100),fill=PAPER);d.rectangle((41,66,88,86),fill=PAPER)
 image.save(OUT/(kind+'.png'))
for kind in IDS:
 strip=Image.new('RGB',(128,512),PAPER);d=ImageDraw.Draw(strip)
 for i,face in enumerate(['speed','guard','charge',kind]):
  d.rectangle((7,i*128+3,120,i*128+9),fill='#e5ac31');d.rectangle((7,i*128+116,120,i*128+124),fill='#e5ac31')
  icon=Image.open(OUT/(face+'.png')).resize((94,94),Image.Resampling.NEAREST)
  strip.paste(icon,(17,i*128+17),icon);d.line([(2,i*128),(2,i*128+127)],fill='#6d9c9a',width=3)
 strip.save(OUT/('reels_'+kind+'.png'))
(OUT/'manifest.json').write_text(json.dumps({'origin':'Original hand-authored Pillow polygon icons; first three retain original project art; no external images','drum_panels':['speed','guard','charge','selected_reward'],'ids':IDS,'files':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(OUT.glob('*.png'))}},indent=2)+'\n')
print('Built',len(IDS),'core icons and matching four-panel strips')
