"""Read-only pixel inspection; writes metadata, never edits the generated PNGs."""
from pathlib import Path
from PIL import Image
import hashlib,json,math
ROOT=Path(__file__).resolve().parents[1]
PACK=ROOT/'references/ui-jsr-2026-11-09'
checks=[]
def check(name,value):checks.append({'name':name,'passed':bool(value)})
def inspect(rel):
 p=PACK/rel;im=Image.open(p);im.load();check(rel+' decodes as RGBA',im.mode=='RGBA')
 a=im.getchannel('A');hist=a.histogram();w,h=im.size
 check(rel+' has genuinely empty corner alpha',all(a.getpixel(xy)==0 for xy in [(0,0),(w-1,0),(0,h-1),(w-1,h-1)]))
 check(rel+' has visible art and a transparent background',hist[0]>w*h*.2 and sum(hist[250:])>w*h*.15)
 bbox=a.point(lambda n:255 if n>=16 else 0).getbbox()
 return im,{'path':rel,'width':w,'height':h,'mode':im.mode,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size,'alpha_zero_fraction':round(hist[0]/(w*h),4),'alpha_near_opaque_fraction':round(sum(hist[250:])/(w*h),4),'significant_alpha_bbox':bbox}
logo,lo=inspect('assets/afterhours-logo.png')
x0,y0,x1,y1=lo['significant_alpha_bbox'];check('logo has at least six percent significant-content padding',min(x0/logo.width,y0/logo.height,(logo.width-x1)/logo.width,(logo.height-y1)/logo.height)>=.06)
frames,fr=inspect('assets/ui-frames.png');check('frame sheet dimensions match slicing contract',frames.size==(1536,1024))
regions=[('button_normal',[0,0,768,256]),('button_selected',[768,0,768,256]),('button_hover',[0,256,768,232]),('button_disabled',[768,256,768,232]),('health_frame',[0,488,768,216]),('energy_ornament',[768,488,768,216]),('timer_dial',[0,704,768,320]),('combo_badge',[768,704,768,320])]
frame_entries=[]
for name,rect in regions:
 x,y,w,h=rect;check(name+' region is bounded',x>=0 and y>=0 and x+w<=frames.width and y+h<=frames.height)
 a=frames.getchannel('A').crop((x,y,x+w,y+h));bbox=a.point(lambda n:255 if n>=16 else 0).getbbox();check(name+' region contains visible art',bbox is not None)
 frame_entries.append({'id':name,'region_xywh':rect,'visible_bbox_in_region':bbox,'status':'decorative_only_rebuild_50_75_ticks_in_code' if name=='energy_ornament' else 'alpha_asset_candidate'})
check('health frame interior is transparent',frames.getpixel((300,610))[3]<=1)
check('timer dial center is transparent',frames.getpixel((380,870))[3]<=1)
icons,ic=inspect('assets/action-icons.png')
names=['jab','launch','slam','cannon','parry','counter','dash','grab','headphones','radio','demo','roster','music','sound','pause','back']
icon_entries=[]
for i,name in enumerate(names):
 col,row=i%4,i//4;x0=math.floor(col*icons.width/4);y0=math.floor(row*icons.height/4);x1=math.floor((col+1)*icons.width/4);y1=math.floor((row+1)*icons.height/4)
 a=icons.getchannel('A').crop((x0,y0,x1,y1));bbox=a.point(lambda n:255 if n>=16 else 0).getbbox()
 check(name+' icon cell is nonempty',bbox is not None)
 icon_entries.append({'id':name,'region_xywh':[x0,y0,x1-x0,y1-y0],'significant_bbox_in_region':bbox})
metadata={'format':'Atlas regions in original PNG pixels; no PNG cropping or retouch performed. Use Godot AtlasTexture.region; filenames are portable pack-relative.','frames':{'image':'assets/ui-frames.png','entries':frame_entries},'icons':{'image':'assets/action-icons.png','entries':icon_entries},'notes':['Energy ornament separators are decorative, not exact 50/75 resource thresholds. Draw actual energy, health, text and state in the engine.','Alpha-zero pixels can retain colored RGB; native alpha-preview is the evidence, not an RGB-only viewer.','Significant bbox threshold is alpha >=16 for inspection only. PNG bytes are preserved.']}
(PACK/'atlas-regions.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2)+'\n')
report={'checks':checks,'passed':sum(c['passed'] for c in checks),'failed':sum(not c['passed'] for c in checks),'assets':[lo,fr,ic],'scope':'Pixel/header/alpha/region inspection plus separately captured native composition. Not game integration, OCR, perceptual QA, or control-state/accessibility verification.'}
(ROOT/'docs/evidence/ui-jsr/asset-inspection.json').write_text(json.dumps(report,indent=2)+'\n')
print(report['passed'],'/',len(checks),'asset checks; failures:',[c['name'] for c in checks if not c['passed']])
raise SystemExit(0 if not report['failed'] else 1)
