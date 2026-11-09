"""Usage: python scan_red_candidates.py VIDEO OUTPUT.json. Requires ffmpeg/ffprobe and numpy."""
import subprocess,json,sys,hashlib
from pathlib import Path
import numpy as np
source=Path(sys.argv[1]);output=Path(sys.argv[2]);name=source.stem
meta=json.loads(subprocess.check_output(['ffprobe','-v','error','-show_entries','format=duration,size','-of','json',str(source)]))['format']
proc=subprocess.Popen(['ffmpeg','-v','error','-threads','2','-i',str(source),'-vf','fps=8,scale=160:90','-f','rawvideo','-pix_fmt','rgb24','-'],stdout=subprocess.PIPE)
reds=[];scan=[];i=0
while True:
 b=proc.stdout.read(160*90*3)
 if len(b)<160*90*3:break
 x=np.frombuffer(b,dtype=np.uint8).reshape(-1,3).astype(np.float32)
 r,g,blue=x[:,0],x[:,1],x[:,2]
 score=float(np.mean((r>115)&(r>g*1.35)&(r>blue*1.25)))
 if score>.35:reds.append({'time':i/8,'red_fraction':round(score,4)})
 if i%80==0:scan.append({'time':i/8,'red_fraction':round(score,4),'brightness':round(float(x.mean()),2)})
 i+=1
if proc.wait()!=0:raise SystemExit("ffmpeg decode failed")
groups=[]
for item in reds:
 if groups and item['time']-groups[-1]['end']<=.26:
  groups[-1]['end']=item['time']
  if item['red_fraction']>groups[-1]['peak']['red_fraction']:groups[-1]['peak']=item
 else:groups.append({'start':item['time'],'end':item['time'],'peak':item})
report={'name':source.name,'sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'duration':float(meta['duration']),'bytes':int(meta['size']),'sampled_frames':i,'sample_fps':8,'threshold':.35,'red_intervals':groups,'overview':scan,'scope':'Full-duration 8fps red-pixel scan, not every 60fps source frame or an audio/game-rules analysis.'}
output.write_text(json.dumps(report,indent=2))
print(name,'frames',i,'red intervals',len(groups),'longest',sorted(groups,key=lambda x:x['end']-x['start'],reverse=True)[:6])
