"""Build a PRIVATE paired throw library from the user's two original FBX files.

blender -b --python tools/import_mixamo_throw.py -- --aggressor /private/a.fbx \
    --victim /private/v.fbx --output /private/mixamo_shoulder_throw.json
Never commit the generated library or original FBX to the public repository.
"""
import argparse
import hashlib
import json
import os
import sys
from pathlib import Path
import bpy

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--aggressor', type=Path, required=True)
parser.add_argument('--victim', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
os.umask(0o077)
repo = Path(__file__).resolve().parents[1]
output = args.output.resolve()
if repo in output.parents and not (repo/'godot/.godot') in output.parents:
    parser.error('Output must be outside the public repo, or inside ignored godot/.godot.')
result = {'schema': 1, 'fps': 30, 'first': 61, 'last': 121, 'impact': 106, 'scale': 1.15, 'planar_scale': 1.0, 'actors': {}}
def vector(v):
    return [round(float(x), 7) for x in v]
def quat(matrix):
    q = matrix.to_quaternion().normalized()
    return vector([q.x, q.y, q.z, q.w])
for role in ['aggressor', 'victim']:
    path = getattr(args, role)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(path), use_anim=True)
    rigs = [o for o in bpy.data.objects if o.type == 'ARMATURE']
    if len(rigs) != 1:
        parser.error(f'{role}: expected one armature')
    rig = rigs[0]
    if not rig.animation_data or not rig.animation_data.action:
        parser.error(f'{role}: missing animation')
    start, end = rig.animation_data.action.frame_range
    fps = bpy.context.scene.render.fps / bpy.context.scene.render.fps_base
    if fps != 30 or start > 61 or end < 121:
        parser.error(f'{role}: expected full original 30fps throw (includes 61–121)')
    names = [b.name for b in rig.data.bones]
    bones = []
    for b in rig.data.bones:
        world = rig.matrix_world @ b.matrix_local
        bones.append({'name': b.name.split(':')[-1].removeprefix('mixamorig_'),
                      'parent': names.index(b.parent.name) if b.parent else -1,
                      'position': vector(world.translation), 'rotation': quat(world)})
    frames = []
    hips = names.index('mixamorig:Hips')
    for frame in range(61, 122):
        bpy.context.scene.frame_set(frame)
        matrices = [rig.matrix_world @ rig.pose.bones[n].matrix for n in names]
        frames.append({'rotations': [quat(m) for m in matrices], 'hip': vector(matrices[hips].translation)})
    result['actors'][role] = {'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                             'bones': bones, 'frames': frames}
if [b['name'] for b in result['actors']['aggressor']['bones']] != [b['name'] for b in result['actors']['victim']['bones']]:
    parser.error('Actor bone names/order differ')
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps(result, separators=(',', ':'))+'\n')
output.chmod(0o600)
print(f'PRIVATE_LIBRARY {output.name}: 2 actors, 61 shared frames, {output.stat().st_size} bytes')
