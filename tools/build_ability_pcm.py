#!/usr/bin/env python3
"""Decode short original intermission cues to PCM, avoiding Ogg decoder retention
under rapid clear/restart on Godot 4.6. Long BGM streams remain untouched."""
from pathlib import Path
import subprocess,json,hashlib,wave
ROOT=Path(__file__).resolve().parents[1]
files=[*sorted((ROOT/'godot/audio/ability_draw').glob('*.ogg')),ROOT/'godot/audio/city_breaker/intro.ogg']
records=[]
for source in files:
    target=source.with_suffix('.wav')
    subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',str(source),'-ar','48000','-ac','2','-c:a','pcm_s16le',str(target)],check=True)
    with wave.open(str(target)) as w:seconds=w.getnframes()/w.getframerate()
    records.append({'source':str(source.relative_to(ROOT)),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'pcm':str(target.relative_to(ROOT)),'pcm_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'seconds':seconds,'channels':2,'rate':48000})
(ROOT/'references/ability-draw/tripo/pcm-cues.json').write_text(json.dumps({'scope':'Decoded copies of already admitted original short cues; no new music or composition changes. Original OGG files retained.','files':records},indent=2)+'\n')
print('Decoded',len(records),'short cues to stereo PCM')
