#!/usr/bin/env python3
"""Original PCM equip cues aligned to authored catches/clamps/power/stomp."""
from pathlib import Path
import json,hashlib,wave
ROOT=Path(__file__).resolve().parents[1]
source=(ROOT/'tools/build_ability_rhythm_audio.py').read_text().split('records=[]')[0]
namespace={'__file__':str(ROOT/'tools/build_ability_rhythm_audio.py')}
exec(compile(source,'rhythm_synthesis_helpers','exec'),namespace)
namespace['OUT']=ROOT/'godot/audio/ability_draw'
render=namespace['render']
records=[render('equip',4.10,[(.02,.32,'whoosh',.45,-.4),(.42,.17,'clack',.7,0),(1.32,.40,'whoosh',.35,.2),(2.34,.14,'clack',.7,-.15),(2.44,.38,'hit',.8,0),(2.72,.48,'spin',.6,.2),(3.30,.55,'hit',1,0),(3.40,.42,'drag',.25,.3)]),render('equip_short',1.15,[(.12,.10,'clack',.6,0),(.68,.20,'hit',.6,0),(.93,.20,'hit',.7,0)])]
(ROOT/'godot/audio/ability_draw/equip-cues.json').write_text(json.dumps({'origin':'Original deterministic synthesis, no source-video audio reused','files':records},indent=2)+'\n')
ref=ROOT/'references/ability-equip/source.mp4'
(ROOT/'references/ability-equip/manifest.json').write_text(json.dumps({'source':'User-uploaded a9b6f872-5d64-47e3-9f92-fb8d363c35c8.mp4','sha256':hashlib.sha256(ref.read_bytes()).hexdigest(),'seconds':4.458333,'review':'Full duration 4fps contact sheet plus representative frames; approximate choreography, not frame-perfect recreation','runtime_seconds':4.1},indent=2)+'\n')
print('Built full and reduced equip PCM')
