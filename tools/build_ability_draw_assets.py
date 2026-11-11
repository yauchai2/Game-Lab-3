#!/usr/bin/env python3
"""Original vector reel art and deterministic layered sound design. No recordings."""
from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np
import wave, subprocess, json, hashlib
ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'godot/assets/ability_draw'; AUDIO=ROOT/'godot/audio/ability_draw'
ART.mkdir(parents=True,exist_ok=True); AUDIO.mkdir(parents=True,exist_ok=True)
INK='#141224'; CYAN='#40f5df'; PAPER='#d8ead7'
for kind in ['speed','guard','charge']:
    image=Image.new('RGBA',(128,128),(0,0,0,0)); d=ImageDraw.Draw(image)
    if kind=='speed': d.polygon([(62,9),(24,73),(58,70),(42,121),(105,48),(70,51),(91,9)],fill=INK)
    elif kind=='guard':
        d.polygon([(17,19),(62,7),(110,19),(104,78),(65,121),(25,83)],fill=INK)
        d.polygon([(32,30),(63,22),(94,31),(88,71),(65,99),(39,74)],fill=PAPER)
    else:
        d.polygon([(17,65),(23,44),(39,43),(39,20),(54,18),(59,44),(62,11),(77,12),(80,44),(86,22),(99,25),(99,52),(110,49),(119,64),(103,101),(75,119),(41,110)],fill=INK)
        for x in [43,63,83]:d.line([(x,53),(x+4,76)],fill=PAPER,width=4)
    image.save(ART/(kind+'.png'))
reels=Image.new('RGB',(128,512),PAPER);d=ImageDraw.Draw(reels)
for i,kind in enumerate(['speed','guard','charge','speed']):
    d.rectangle((0,i*128,127,i*128+127),fill=PAPER)
    d.rectangle((7,i*128+3,120,i*128+9),fill='#e5ac31')
    d.rectangle((7,i*128+116,120,i*128+124),fill='#e5ac31')
    icon=Image.open(ART/(kind+'.png')).resize((94,94),Image.Resampling.NEAREST)
    reels.paste(icon,(17,i*128+17),icon)
    d.line([(2,i*128),(2,i*128+127)],fill='#6d9c9a',width=3)
reels.save(ART/'reels.png')
RATE=48000;rng=np.random.default_rng(20261111)
def noise(n,cut=4000):
    a=rng.normal(size=n);f=np.fft.rfftfreq(n,1/RATE)
    a=np.fft.irfft(np.fft.rfft(a)/(1+(f/cut)**4),n=n)
    return a/max(np.std(a),1e-9)
def render(name,duration,events,loop=False):
    mix=np.zeros((int(duration*RATE),2))
    def add(at,sig,gain=1,pan=0):
        i=int(at*RATE);n=min(len(sig),len(mix)-i)
        if n<=0:return
        a=(pan+1)*np.pi/4;mix[i:i+n]+=sig[:n,None]*np.array([np.cos(a),np.sin(a)])*gain
    for event in events:
        at,length,kind,gain,pan=event;t=np.arange(int(length*RATE))/RATE
        env=np.minimum(t/.004,1)*np.exp(-t/max(.018,length*.23))
        if kind=='hit':sig=(np.sin(2*np.pi*(43*t+2.8*(1-np.exp(-t/.025))))*.65+noise(len(t),5200)*np.exp(-t/.024)*.45+noise(len(t),380)*.18)*env
        elif kind=='metal':sig=sum(np.sin(2*np.pi*f*t)*np.exp(-t/(.03+j*.018)) for j,f in enumerate([431,713,1379,2391]))*.22*env
        elif kind=='rise':sig=(noise(len(t),2400)*.5+np.sin(2*np.pi*np.cumsum(150+2100*(t/length)**2)/RATE)*.18)*np.sin(np.pi*t/length)**1.4
        elif kind=='chord':sig=sum(np.sin(2*np.pi*f*t)*np.exp(-t/.35) for f in [261.63,329.63,392,523.25])*.17*np.minimum(1,t/.009)
        elif kind=='drag':sig=(noise(len(t),2100)*.20+np.sin(2*np.pi*91*t)*.10)*(0.7+0.3*np.sin(t*49)**2)
        else:sig=(np.sin(2*np.pi*67*t)*.16+noise(len(t),3200)*.1)*(0.6+0.4*np.sin(t*90)**8)
        add(at,sig,gain,pan)
    if loop:
        n=600;fade=np.linspace(0,1,n);mix[:n]*=fade[:,None];mix[-n:]*=fade[::-1,None]
    else:
        n=min(1200,len(mix));mix[-n:]*=np.linspace(1,0,n)[:,None]
    # Soft saturation, then normalize with a predictable headroom.
    mix=np.tanh(mix);peak=np.max(np.abs(mix));mix*=.75/max(peak,1e-9)
    path=AUDIO/(name+'.wav')
    with wave.open(str(path),'wb') as w:w.setnchannels(2);w.setsampwidth(2);w.setframerate(RATE);w.writeframes((mix*32767).astype('<i2').tobytes())
    subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',str(path),'-c:a','libvorbis','-q:a','5',str(path.with_suffix('.ogg'))],check=True)
    path.unlink()
render('arrival',1.95,[(0,.36,'drag',.35,-.7),(.18,.62,'drag',.55,-.5),(.50,.52,'drag',.6,-.2),(1.05,.7,'hit',1,0),(1.10,.65,'metal',.4,.3),(1.34,.5,'hit',1,0),(1.40,.4,'metal',.5,.2),(1.55,.32,'rise',.3,0)])
render('spin',1.3,[(i*.07,.10,'metal',.20,(-.4 if i%2 else .4)) for i in range(18)],True)
render('reveal',1.85,[(0,.12,'metal',.45,-.5),(.12,.12,'metal',.6,0),(.25,.16,'metal',.8,.5),(.26,.10,'rise',.45,0),(.38,.75,'hit',.9,0),(.42,.8,'chord',.65,0),(.62,.42,'rise',.3,0)])
render('coin',.4,[(0,.32,'metal',.5,0)])
render('confirm',.6,[(0,.5,'chord',.5,0)])
# Keep runtime PCM copies synchronized when rebuilding the original OGG cues.
subprocess.run(['python3',str(ROOT/'tools/build_ability_pcm.py')],check=True)
manifest={'origin':'Original programmatic polygon icon art and deterministic synthesis; no external recordings','seed':20261111,'rate':RATE,'source_video_sha256':hashlib.sha256((ROOT/'references/ability-draw/source.mp4').read_bytes()).hexdigest(),'source_duration_seconds':4.351969,'source_review':'Full-duration 4fps sampling; cut points approximated, not source-PTS locked','files':{str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted([*ART.glob('*.png'),*AUDIO.glob('*.ogg')])}}
storyboard=ROOT/'references/ability-draw/equip-storyboard.png'
if storyboard.exists():manifest['equip_storyboard']={'origin':'ImageGen concept sheet using existing capsule screenshot as design reference','status':'planning_only_not_runtime','sha256':hashlib.sha256(storyboard.read_bytes()).hexdigest()}
(ROOT/'references/ability-draw/manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
subprocess.run(['python3',str(ROOT/'tools/build_ability_core_art.py')],check=True)
print('Built reel art, expanded core pool, 5 original stereo cues and provenance manifest')
