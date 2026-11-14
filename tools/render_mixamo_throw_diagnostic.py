"""Diagnostic rendering of evaluated FBX joints; no retiming or alignment."""
import argparse, json, subprocess
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--private-samples', required=True, type=Path)
args = parser.parse_args()
root = args.private_samples
actors = {r: json.loads((root / f'{r}-private-samples.json').read_text()) for r in ['aggressor', 'victim']}
if any(len(a['frames']) != 201 or a['fps'] != 30 for a in actors.values()):
    parser.error('This diagnostic layout expects the inspected 201-frame, 30fps pair.')
dest = root / 'frames'
dest.mkdir(exist_ok=True)
try:
    font = ImageFont.truetype('DejaVuSans.ttf', 19)
    small = ImageFont.truetype('DejaVuSans.ttf', 15)
except OSError:
    font = ImageFont.load_default(size=19)
    small = ImageFont.load_default(size=15)
colors = {'aggressor': '#36d9ed', 'victim': '#ff789d'}
def project(p, view):
    x,y,z = p
    if view == 0:
        return (235 + 67*x + 18*y, 350 - 90*z + 8*y)
    return (715 + 80*y + 20*x, 350 - 90*z + 6*x)

for i in range(201):
    im=Image.new('RGB',(960,450),'#111923'); d=ImageDraw.Draw(im)
    d.text((20,12),'MIXAMO SOURCE PAIR | FBX joint diagnostic',fill='white',font=font)
    d.text((20,42),'Aggressor',fill=colors['aggressor'],font=font)
    d.text((160,42),'Victim',fill=colors['victim'],font=font)
    d.text((685,42),f'frame {i+1:03d} / 201 | {i/30:.2f}s',fill='white',font=small)
    for view in [0,1]:
        d.text((20+view*480,83),['Front / depth oblique','Side / depth oblique'][view],fill='#b8c6d3',font=small)
        d.line([(480,80),(480,390)],fill='#344251',width=1)
        for x in range(-4,5):
            d.line([project((x,-2,0),view),project((x,2,0),view)],fill='#263644')
        for y in range(-2,3):
            d.line([project((-4,y,0),view),project((4,y,0),view)],fill='#263644')
        for role, actor in actors.items():
            frame=actor['frames'][i]
            for name, bone in actor['bones'].items():
                parent=bone['parent']
                if parent is None or any(t in name for t in ['Thumb','Index','Middle','Ring','Pinky','Top_End','Toe_End']):continue
                d.line([project(frame[parent],view),project(frame[name],view)],fill=colors[role],width=4)
            p=project(frame['mixamorig:Head'],view)
            d.ellipse((p[0]-8,p[1]-8,p[0]+8,p[1]+8),outline=colors[role],width=3)
    d.text((20,405),'Same source frame; original world positions; no offsets, IK or time warp.',fill='#c5cfda',font=small)
    d.text((20,427),'Diagnostic only: not a Godot retarget, collision test or mesh contact verification.',fill='#c5cfda',font=small)
    im.save(dest/f'{i:04d}.png')
chosen=[0,30,45,60,75,80,85,90,95,100,105,120]
sheet=Image.new('RGB',(1440,900),'#111923')
for j,i in enumerate(chosen):
    with Image.open(dest/f'{i:04d}.png') as im:
        sheet.paste(im.resize((480,225)),((j%3)*480,(j//3)*225))
sheet.save(root/'source-pair-contact-sheet.jpg',quality=92)
subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-framerate','30','-i',str(dest/'%04d.png'),'-c:v','libx264','-crf','20','-pix_fmt','yuv420p','-movflags','+faststart',str(root/'source-pair.mp4')],check=True)
print('Rendered 201 source samples, contact sheet and 6.7s diagnostic video')
