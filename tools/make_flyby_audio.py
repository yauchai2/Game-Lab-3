"""Generate an original deterministic looping engine-like placeholder; not a field recording."""
from pathlib import Path
import math,random,struct,wave
rate=22050; duration=4; count=rate*duration; rng=random.Random(1847); low=0.0; samples=[]
for i in range(count):
    t=i/rate
    low += .06*(rng.uniform(-1,1)-low)
    pulse=1+.12*math.sin(2*math.pi*1.25*t)
    v=.27*math.sin(2*math.pi*54*t)+.15*math.sin(2*math.pi*91*t)+.10*math.sin(2*math.pi*136*t)+.50*low*pulse
    samples.append(v)
# Blend boundaries to suppress clicks when looping.
blend=int(.08*rate)
for i in range(blend):
    weight=i/blend
    mixed=samples[count-blend+i]*(1-weight)+samples[i]*weight
    samples[count-blend+i]=mixed
peak=max(abs(x) for x in samples)
pcm=b''.join(struct.pack('<h',round(max(-1,min(1,x/peak*.8))*32767)) for x in samples)
out=Path(__file__).resolve().parents[1]/'godot/audio/engine_placeholder.wav'
with wave.open(str(out),'wb') as f:
    f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(pcm)
print(f'Generated {duration}s mono {rate}Hz procedural placeholder: {out}')
