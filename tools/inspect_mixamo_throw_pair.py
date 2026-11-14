"""Blender FBX metadata + private world-joint sampling, never a public motion export.

Usage: blender -b --python tools/inspect_mixamo_throw_pair.py -- \
    --aggressor /private/aggressor.fbx --victim /private/victim.fbx \
    --out-private /private/throw-inspection
"""
import bpy, hashlib, json
from pathlib import Path

import argparse, sys

parser = argparse.ArgumentParser(description="Inspect two FBX throws without changing source positions or timing.")
parser.add_argument('--aggressor', type=Path, required=True)
parser.add_argument('--victim', type=Path, required=True)
parser.add_argument('--out-private', type=Path, required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
sources = {'aggressor': args.aggressor, 'victim': args.victim}
out = args.out_private.resolve()
repo_root = Path(__file__).resolve().parents[1]
if out == repo_root or repo_root in out.parents:
    parser.error('Private evaluated motion samples must be outside the public repository.')
out.mkdir(parents=True, exist_ok=True)
report = {'provenance': 'User-uploaded FBX; no Mixamo API download in this session', 'actors': {}}
for role, path in sources.items():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(path), use_anim=True)
    rig = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
    action = rig.animation_data.action
    first, last = [int(x) for x in action.frame_range]
    fps = bpy.context.scene.render.fps / bpy.context.scene.render.fps_base
    frames = []
    for frame in range(first, last + 1):
        bpy.context.scene.frame_set(frame)
        frames.append({b.name: list(rig.matrix_world @ b.head) for b in rig.pose.bones})
    rest = {b.name: {'parent': b.parent.name if b.parent else None, 'head': list(rig.matrix_world @ b.head_local)} for b in rig.data.bones}
    (out / f'{role}-private-samples.json').write_text(json.dumps({'fps': fps, 'first_frame': first, 'bones': rest, 'frames': frames}))
    report['actors'][role] = {'filename': path.name, 'bytes': path.stat().st_size, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'bone_count': len(rig.data.bones), 'bone_names': list(rest), 'frame_range': [first, last], 'fps': fps, 'duration_seconds': (last-first)/fps, 'root': [b.name for b in rig.data.bones if b.parent is None], 'hip_samples_meters': {str(f): frames[f-first]['mixamorig:Hips'] for f in [first, (first+last)//2, last]}}
report['same_bone_names'] = report['actors']['aggressor']['bone_names'] == report['actors']['victim']['bone_names']
(out / 'inspection.json').write_text(json.dumps(report, indent=2))
print(json.dumps({k: {kk: vv for kk, vv in v.items() if kk != 'bone_names'} for k,v in report['actors'].items()}, indent=2))
