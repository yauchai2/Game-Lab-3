#!/usr/bin/env python3
"""Original deterministic stereo KO sound design; no external recordings.
48kHz render, noise seed 20261111. Output score follows cinematic seconds.
"""
from pathlib import Path
import json, subprocess, wave
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
RATE=48000
TIMING=json.loads((ROOT/"godot/audio/city_breaker/timing.json").read_text())
DURATION=TIMING["duration"]
def playback(t):return float(np.interp(t,TIMING["source"],TIMING["playback"]))
def span(at,duration):return playback(at+duration)-playback(at)
rng=np.random.default_rng(20261111)
mix=np.zeros((int(RATE*DURATION),2),dtype=np.float64)
CUES=[(0.02,1.0,-.4),(.82,1.0,.7),(1.72,.85,-.65),(2.82,.85,.55),(3.18,.9,-.6),(3.65,1.05,.5),(6.4,1.0,.15),(172/24,1.45,0),(189/24,.8,0)]
def fade(t,duration):return np.minimum(1,t/.008)*np.clip((duration-t)/.09,0,1)
def low_noise(n,cut):
    signal=rng.normal(0,1,n)
    spectrum=np.fft.rfft(signal)
    freq=np.fft.rfftfreq(n,1/RATE)
    spectrum*=1/np.sqrt(1+(freq/cut)**6)
    result=np.fft.irfft(spectrum,n=n)
    return result/max(np.std(result),1e-8)
def add(at,signal,gain=1,pan=0,echo=False):
    start=int(at*RATE)
    n=min(len(signal),len(mix)-start)
    if n<=0 or start<0:return
    p=np.asarray(pan)
    if p.ndim:p=p[:n]
    angle=(np.clip(p,-1,1)+1)*np.pi/4
    mix[start:start+n,0]+=signal[:n]*gain*np.cos(angle)
    mix[start:start+n,1]+=signal[:n]*gain*np.sin(angle)
    if echo:
        add(at+.13,signal,gain*.16,-float(np.mean(p)))
        add(at+.29,signal,gain*.07,float(np.mean(p)))
def impact(at,power,pan):
    duration=1.3 if power<1.2 else 2.1
    t=np.arange(int(RATE*duration))/RATE
    phase=2*np.pi*(32*t+55*.035*(1-np.exp(-t/.035)))
    sub=np.sin(phase)*np.exp(-t/(.24 if power<1.2 else .48))*.6
    boom=low_noise(len(t),320)*np.exp(-t/.23)*.23
    crack=low_noise(len(t),8500)*np.exp(-t/.022)*.32
    gravel=low_noise(len(t),2200)*(np.sin(t*83)**6)*np.exp(-t/.48)*.09
    add(at,(sub+boom+crack+gravel)*fade(t,duration),power,pan,True)
    # Metal shards ring after the transient, with inharmonic partials.
    for i,f in enumerate([733,1099,1931,2877]):
        ring=np.sin(2*np.pi*f*t+np.sin(t*27)*.1)*np.exp(-t/(.12+i*.055))*fade(t,duration)
        add(at+.025+i*.009,ring,.018*power,pan*(-1 if i%2 else 1))
for at,power,pan in CUES:impact(playback(at),power,pan)
# Stereo rising flyaway / pressure trails, with holes for the impacts to breathe.
for at,duration,start_freq,end_freq,gain in [(0, .73,90,1200,.15),(.95,2.65,180,1600,.10),(4.9,1.5,90,1800,.15)]:
    duration=span(at,duration);at=playback(at)
    t=np.arange(int(RATE*duration))/RATE
    f=start_freq+(end_freq-start_freq)*(t/duration)**1.4
    noise=low_noise(len(t),3800)
    sig=(noise*.6+np.sin(2*np.pi*np.cumsum(f)/RATE)*.2)*np.sin(np.pi*t/duration)**1.1
    add(at,sig,gain,np.sin(t*1.4-.7))
# Reverse suction just before the aircraft rupture.
suction=span(6.72,.42)
t=np.arange(int(RATE*suction))/RATE
add(playback(6.72),low_noise(len(t),1400)*(t/suction)**2,.16,0)
# Four-engine rumble: deliberately synthetic, not a downloaded aircraft recording.
engine_duration=span(5.18,1.25)
t=np.arange(int(RATE*engine_duration))/RATE
engine=(np.sin(2*np.pi*51*t)+.3*np.sin(2*np.pi*103*t)+low_noise(len(t),550)*.18)
add(playback(5.18),engine*np.sin(np.pi*t/engine_duration)**2,.095,np.linspace(-.65,.5,len(t)))
# Flying debris after the blast; staggered pans and decays.
for i in range(10):
    duration=.22+rng.random()*.22;t=np.arange(int(RATE*duration))/RATE
    add(playback(7.25+i*.17),low_noise(len(t),1800+rng.random()*3000)*np.exp(-t/.09)*fade(t,duration),.022,(-1 if i%2 else 1)*.8)
# KO punctuation: descending arcade chord, rather than a synthetic spoken voice.
for at,f,gain in [(7.91,146.83,.12),(8.04,110,.11),(8.18,73.42,.13)]:
    t=np.arange(int(RATE*.6))/RATE
    tone=sum(np.sin(2*np.pi*f*k*t)/k for k in [1,2,3])
    add(playback(at),tone*np.exp(-t/.17)*fade(t,.6),gain,0)
# Gentle saturation and a documented fixed peak leave room for in-game BGM.
peak=float(np.max(np.abs(mix)))
mix=np.tanh(mix/max(peak,.001)*1.15)
mix*=10**(-2/20)/np.max(np.abs(mix))
mix[-int(.15*RATE):]*=np.linspace(1,0,int(.15*RATE))[:,None]
pcm=(mix*32767).astype('<i2')
out=ROOT/'godot/audio/city_breaker'
out.mkdir(parents=True,exist_ok=True)
wav=Path('/tmp/city-breaker-score.wav')
with wave.open(str(wav),'wb') as f:f.setnchannels(2);f.setsampwidth(2);f.setframerate(RATE);f.writeframes(pcm.tobytes())
subprocess.run(['ffmpeg','-v','error','-i',str(wav),'-c:a','libvorbis','-q:a','5',str(out/'score.ogg'),'-y'],check=True)
(out/'provenance.json').write_text(json.dumps({'source':'Original procedural synthesis; no external samples','generator':'tools/build_city_breaker_audio.py','seed':20261111,'duration_seconds':DURATION,'sample_rate':RATE,'channels':2,'peak_dbfs_before_vorbis':-2,'impact_seconds':[playback(c[0]) for c in CUES],'authored_impact_seconds':[c[0] for c in CUES],'timing_profile':'godot/audio/city_breaker/timing.json'},indent=2)+'\n')
print(out/'score.ogg')

# Four original 3.2-second victory signatures and footstep patterns.
for character in ['zip','rivet','hush','loop']:
    DURATION=3.2
    mix=np.zeros((int(RATE*DURATION),2),dtype=np.float64)
    def tone(at,f,duration,gain,pan=0):
        t=np.arange(int(RATE*duration))/RATE
        signal=(np.sin(2*np.pi*f*t)+.22*np.sin(2*np.pi*f*2.01*t))*np.exp(-t/.12)*fade(t,duration)
        add(at,signal,gain,pan)
    t=np.arange(int(RATE*.28))/RATE
    add(.02,low_noise(len(t),2800)*np.sin(np.pi*t/.28)**2,.12,-.3)
    if character=='zip':
        for i,f in enumerate([880,1320,1760]):tone(.10+i*.075,f,.23,.09,-.3+i*.3)
        impact(.12,.25,0)
        steps=[1.48,2.10,2.73]
    elif character=='rivet':
        impact(.10,.8,0)
        for i,f in enumerate([230,347,491]):tone(.22+i*.07,f,.32,.07,(-1 if i%2 else 1)*.4)
        steps=[1.47,2.25,2.96]
    elif character=='hush':
        tone(.12,680,.22,.055,.3)
        for at in [.32,.58]:
            t=np.arange(int(RATE*.10))/RATE
            add(at,low_noise(len(t),6500)*np.exp(-t/.009)*fade(t,.1),.12,-.2)
        steps=[1.53,2.35,2.98]
    else:
        for i,f in enumerate([330,495,660,990]):tone(.10+i*.085,f,.26,.095,(-1 if i%2 else 1)*.55)
        steps=[1.49,2.14,2.81]
    for i,at in enumerate(steps):
        if character=='rivet':impact(at,.23,.35)
        t=np.arange(int(RATE*.18))/RATE
        foot=low_noise(len(t),550 if character=='rivet' else 1800)*np.exp(-t/.028)*fade(t,.18)
        add(at,foot,.13 if character=='rivet' else .065,(-.7 if character in ['zip','hush'] else .7)*(i+1)/3)
        if character=='zip':add(at+.02,low_noise(len(t),2400)*np.exp(-t/.07)*fade(t,.18),.035,-.6)
    target={'zip':-3,'rivet':-2,'hush':-6,'loop':-3}[character]
    mix=np.tanh(mix)
    mix*=10**(target/20)/max(.001,np.max(np.abs(mix)))
    mix[-int(.15*RATE):]*=np.linspace(1,0,int(.15*RATE))[:,None]
    wav=Path('/tmp/exit_'+character+'.wav')
    with wave.open(str(wav),'wb') as f:f.setnchannels(2);f.setsampwidth(2);f.setframerate(RATE);f.writeframes((mix*32767).astype('<i2').tobytes())
    subprocess.run(['ffmpeg','-v','error','-i',str(wav),'-c:a','libvorbis','-q:a','5',str(out/('exit_'+character+'.ogg')),'-y'],check=True)
(out/'exit-provenance.json').write_text(json.dumps({'source':'Original procedural synthesis, no external samples','duration':3.2,'characters':['zip','rivet','hush','loop'],'sample_rate':RATE,'channels':2,'generator':'tools/build_city_breaker_audio.py'},indent=2)+'\n')
