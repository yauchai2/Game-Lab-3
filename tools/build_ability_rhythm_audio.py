#!/usr/bin/env python3
"""Original short PCM cues aligned to the ability-draw real-time profile.
No new music, external recordings, or global audio pitch/time scaling."""
from pathlib import Path
import numpy as np,wave,json,hashlib
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'godot/audio/ability_draw/rhythm';OUT.mkdir(parents=True,exist_ok=True)
RATE=48000;rng=np.random.default_rng(2026111103)
def noise(n,cut):
 x=rng.normal(size=n);f=np.fft.rfftfreq(n,1/RATE);x=np.fft.irfft(np.fft.rfft(x)/(1+(f/cut)**4),n=n);return x/max(1e-8,np.std(x))
def render(name,duration,events):
 mix=np.zeros((int(duration*RATE),2))
 for at,length,kind,gain,pan in events:
  t=np.arange(int(length*RATE))/RATE;env=np.minimum(1,t/.003)*np.exp(-t/max(.012,length*.22))
  if kind=='hit':x=(np.sin(2*np.pi*(44*t+2.7*(1-np.exp(-t/.025))))*.60+noise(len(t),4200)*np.exp(-t/.015)*.30+noise(len(t),300)*.14)*env
  elif kind=='clack':x=(np.sin(2*np.pi*731*t)+.4*np.sin(2*np.pi*1499*t)+noise(len(t),4200)*.5)*env*.28
  elif kind=='drag':x=(noise(len(t),1800)*.20+np.sin(2*np.pi*89*t)*.06)*np.sin(np.pi*t/length)**.5
  elif kind=='spin':
   frequency=180+1100*np.sin(np.pi*t/length)**.6
   x=(np.sin(2*np.pi*np.cumsum(frequency)/RATE)*.06+noise(len(t),2500)*.13)*(np.sin(np.pi*t/length)**.5)
  else:x=noise(len(t),2000)*np.sin(np.pi*t/length)**1.5*.20
  start=int(at*RATE);n=min(len(x),len(mix)-start)
  if n<=0:continue
  angle=(pan+1)*np.pi/4;mix[start:start+n]+=x[:n,None]*np.array([np.cos(angle),np.sin(angle)])*gain
 mix=np.tanh(mix);mix*=.72/max(1e-8,np.max(np.abs(mix)))
 mix[-600:]*=np.linspace(1,0,600)[:,None]
 path=OUT/(name+'.wav')
 with wave.open(str(path),'wb') as w:w.setnchannels(2);w.setsampwidth(2);w.setframerate(RATE);w.writeframes((mix*32767).astype('<i2').tobytes())
 return {'path':str(path.relative_to(ROOT)),'seconds':duration,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'events':[{'at':a,'kind':k} for a,l,k,g,p in events]}
records=[]
records.append(render('arrival',2.05,[(.08,.30,'drag',.28,-.7),(.22,.64,'drag',.5,-.4),(.34,.08,'clack',.25,-.4),(.64,.08,'clack',.25,-.2),(1.04,.60,'hit',.9,0),(1.38,.45,'hit',1,0),(1.48,.22,'clack',.25,.1)]))
records.append(render('spin',1.48,[(.02,1.30,'spin',.35,0),(.13,.05,'clack',.25,-.25),(.31,.05,'clack',.2,.25),(1.02,.07,'clack',.7,-.5),(1.20,.07,'clack',.8,0),(1.39,.07,'clack',1,.5)]))
records.append(render('reveal',.85,[(0,.48,'hit',1,0),(.03,.38,'whoosh',.6,.2),(.21,.18,'clack',.2,0)]))
(OUT/'cues.json').write_text(json.dumps({'seed':2026111103,'rate':RATE,'format':'PCM16 stereo','reel_stops':[1.02,1.20,1.39],'reveal_at':1.61,'files':records},indent=2)+'\n')
print('Built',len(records),'timed PCM cues')
