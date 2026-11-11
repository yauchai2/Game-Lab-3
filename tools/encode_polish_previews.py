#!/usr/bin/env python3
"""Encode native fixed-step captures; these GIFs are not real-time FPS samples."""
from pathlib import Path
import argparse
import hashlib
import json
import subprocess
import shutil
from PIL import Image, ImageDraw, ImageFont, ImageSequence

ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument("--frames",type=Path,default=Path("/tmp/afterhours-polish-frames"))
parser.add_argument("--output",type=Path,default=ROOT/"docs/evidence/extended-polish/previews")
args=parser.parse_args()
args.output.mkdir(parents=True,exist_ok=True)
examples=[]
report=[]
for clip in ["throw","edge_recovery"]:
    paths=sorted((args.frames/clip).glob("*.png"))
    if len(paths)!=90:
        raise SystemExit(f"Expected 90 native frames for {clip}, found {len(paths)}")
    frames=[]
    for path in paths:
        with Image.open(path) as source:frames.append(source.convert("RGB"))
    preview=[frame.resize((640,360),Image.Resampling.NEAREST) for frame in frames]
    strip=Image.new("RGB",(preview[0].width*3,preview[0].height))
    for x,index in enumerate([0,17,24]):strip.paste(preview[index],(preview[0].width*x,0))
    palette=strip.quantize(colors=256,method=Image.Quantize.MEDIANCUT)
    indexed=[f.quantize(palette=palette,dither=Image.Dither.NONE) for f in preview]
    durations=[40 if i%3==2 else 30 for i in range(len(indexed))]
    target=args.output/(clip+".gif")
    indexed[0].save(target,save_all=True,append_images=indexed[1:],loop=0,
                    duration=durations,disposal=1,optimize=False)
    with Image.open(target) as gif:
        encoded_ms=sum(frame.info.get("duration",0) for frame in ImageSequence.Iterator(gif))
        encoded_frames=gif.n_frames
    video=args.output/(clip+".mp4")
    if shutil.which("ffmpeg"):
        subprocess.run(["ffmpeg","-v","error","-y","-framerate","30","-i",str(args.frames/clip/"%03d.png"),"-c:v","libx264","-preset","fast","-crf","18","-pix_fmt","yuv420p","-movflags","+faststart","-an",str(video)],check=True)
    report.append({"clip":clip,"native_size":[frames[0].width,frames[0].height],"gif_size":[640,360],"mp4_bytes":video.stat().st_size if video.exists() else None,"native_frames":len(frames),"encoded_frames":encoded_frames,
                   "encoded_duration_ms":encoded_ms,"average_fps":30,
                   "png_sequence_sha256":hashlib.sha256(b"".join(hashlib.sha256(p.read_bytes()).digest() for p in paths)).hexdigest(),
                   "gif_sha256":hashlib.sha256(target.read_bytes()).hexdigest(),"bytes":target.stat().st_size})
    for index in ([12,17,23] if clip=="throw" else [0,4,18]):
        examples.append((clip,index,frames[index]))
font=ImageFont.truetype(str(ROOT/"godot/assets/fonts/DejaVuSansCondensed-Bold.ttf"),20)
sheet=Image.new("RGB",(1920,3*576),(10,32,40))
draw=ImageDraw.Draw(sheet)
for i,(clip,index,frame) in enumerate(examples):
    x=(i%2)*960;y=(i//2)*576
    draw.text((x+18,y+7),f"{clip.upper()} / FRAME {index:02d}",fill=(244,234,216),font=font)
    sheet.paste(frame,(x,y+36))
sheet.save(args.output/"combat-contact-sheet.jpg",quality=92)
data={"source_commit":subprocess.check_output(["git","rev-parse","HEAD"],cwd=ROOT,text=True).strip(),
      "method":"native fixed simulation-step capture, 2 x 60 Hz ticks per image; GIF 30/30/40 ms cadence averages 30 FPS; not measured real-time FPS, audio or human playtesting",
      "clips":report}
(args.output/"animation.json").write_text(json.dumps(data,indent=2)+"\n")
print(json.dumps(data,indent=2))
