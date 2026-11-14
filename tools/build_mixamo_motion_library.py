"""Blender: convert inspected private Mixamo samples to the game's canonical rig.

blender -b --python tools/build_mixamo_motion_library.py -- --samples <private-dir> --output <private.json>
Input is produced by inspect_mixamo_batch.py. User authorized bundled derived curves on 2026-11-14.
Sample numbers below are one based, sampled at 30 Hz (also for the glTF source).
"""
import argparse
import hashlib
import json
import os
import sys
from pathlib import Path
from mathutils import Matrix, Quaternion, Vector

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--samples', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
repo = Path(__file__).resolve().parents[1]
output = args.output.resolve()
if repo in output.parents and repo / 'godot/.godot' not in output.parents and repo / 'godot/assets/animations' not in output.parents:
    parser.error('Output must be in assets/animations, ignored godot/.godot, or outside the repository')
os.umask(0o077)
base_path = repo / 'godot/assets/animations/quaternius_combat.json'
base = json.loads(base_path.read_text())
nodes = base['nodes']
names = {'Hips': 'DEF-hips', 'Spine': 'DEF-spine.001', 'Spine1': 'DEF-spine.002',
         'Spine2': 'DEF-spine.003', 'Neck': 'DEF-neck', 'Head': 'DEF-head'}
for side, suffix in [('Left', '.L'), ('Right', '.R')]:
    for a, b in [('Shoulder', 'shoulder'), ('Arm', 'upper_arm'), ('ForeArm', 'forearm'),
                 ('Hand', 'hand'), ('UpLeg', 'thigh'), ('Leg', 'shin'), ('Foot', 'foot'), ('ToeBase', 'toe')]:
        names[side + a] = 'DEF-' + b + suffix
    for a, b in [('Thumb', 'thumb'), ('Index', 'f_index'), ('Middle', 'f_middle'), ('Ring', 'f_ring'), ('Pinky', 'f_pinky')]:
        for digit in range(1, 4):
            names[side + 'Hand' + a + str(digit)] = f'DEF-{b}.0{digit}{suffix}'
mapping = {i: a for a, b in names.items() for i, node in enumerate(nodes) if node['name'] == b}
indices = {node['name']: i for i, node in enumerate(nodes)}
def quat(v): return Quaternion((v[3], v[0], v[1], v[2])).normalized()
def packed(q): return [round(v, 7) for v in (q.x, q.y, q.z, q.w)]
rests = {}
def rest(i):
    if i not in rests:
        n = nodes[i]
        local = Matrix.LocRotScale(Vector(n['translation']), quat(n['rotation']), Vector((1, 1, 1)))
        rests[i] = rest(n['parent']) @ local if n['parent'] >= 0 else local
    return rests[i]
for i in range(len(nodes)): rest(i)
def frame(right, up):
    x = right.normalized()
    y = (up - x * up.dot(x)).normalized()
    return Matrix((x, y, x.cross(y).normalized())).transposed()
def target_pos(name): return rest(indices[names[name]]).translation
target_frame = frame(target_pos('RightArm') - target_pos('LeftArm'), target_pos('Head') - target_pos('Hips'))
hip_index = indices[names['Hips']]
specs = [
    ('MX_Jab', 13, 8, 19, 14, 'LeftHand'),
    ('MX_Cross', 13, 17, 45, 22, 'RightHand'),
    ('MX_Hook', 12, 10, 55, 31, 'LeftHand'),
    ('MX_BodyPunch', 10, 8, 47, 22, 'RightHand'),
    ('MX_Idle', 14, 1, 110, None, ''),
    ('MX_HushJab', 11, 19, 40, 31, 'LeftHand'),
    ('MX_HushElbow', 11, 39, 80, 49, 'RightForeArm'),
    ('MX_Elbow', 9, 13, 47, 23, 'RightForeArm'),
    ('MX_Block', 8, 8, 37, 18, ''),
    ('MX_Dodge', 7, 8, 54, None, ''),
    ('MX_StickHorizontal', 6, 12, 57, 29, 'BatonTip'),
    ('MX_StickDown', 4, 9, 54, 26, 'BatonTip'),
    ('MX_StickBack', 3, 12, 69, 32, 'BatonTip'),
    ('MX_Roundhouse', 16, 14, 54, 31, 'LeftFoot'),
    ('MX_Hurricane', 17, 8, 21, 15, 'LeftFoot'),
    ('MX_AirKick', 18, 24, 57, 42, 'LeftFoot'),
    ('MX_HeadHit', 5, 5, 30, None, ''),
    ('MX_BodyHit', 1, 4, 30, None, ''),
    ('MX_KnockedOut', 0, 40, 121, None, ''),
    ('MX_GetUp', 2, 75, 187, None, ''),
    ('MX_Walking', 21, 16, 47, None, ''),
]
clips, markers, manifest = {}, {}, []
inspection = json.loads((args.samples / 'inspection.json').read_text())
expected = {
    0: 'Knocked Out.fbx', 1: 'Hit To Body.fbx', 2: 'Getting Up.fbx',
    3: 'Standing Melee Attack Backhand.fbx', 4: 'Standing Melee Attack Downward.fbx',
    5: 'Head Hit.fbx', 6: 'Standing Melee Attack Horizontal.fbx', 7: 'Dodging.fbx',
    8: 'Inward Block.fbx', 9: 'Illegal Elbow Punch.fbx', 10: 'Boxing.fbx',
    11: 'Jab To Elbow Punch.fbx', 12: 'Hook.fbx', 13: 'Jab Cross.fbx',
    14: 'Idle.fbx', 16: 'Roundhouse Kick.fbx', 17: 'Hurricane Kick.fbx',
    18: 'Kicking.fbx', 21: 'Walking.glb',
}
for key, number, first, last, contact, limb in specs:
    matches = [i for i, row in enumerate(inspection) if row['filename'] == expected[number]]
    if len(matches) != 1:
        parser.error(f'Expected exactly one {expected[number]} in inspection.json')
    number = matches[0]
    raw = json.loads((args.samples / f'{number:02d}-private-samples.json').read_text())
    if raw['name'] != inspection[number]['filename']:
        parser.error('Sample/inspection filename mismatch; re-run inspection')
    bones = raw['bones']
    def pos(name): return Vector(bones[name]['position'])
    align = (target_frame @ frame(pos('RightArm') - pos('LeftArm'), pos('Head') - pos('Hips')).inverted()).to_quaternion()
    calibrated = {}
    for i, name in mapping.items():
        q = rest(i).to_quaternion()
        for child, child_name in mapping.items():
            if nodes[child]['parent'] == i:
                direction = rest(child).translation - rest(i).translation
                source_direction = align @ (pos(child_name) - pos(name))
                if min(direction.length, source_direction.length) > .0001:
                    q = direction.normalized().rotation_difference(source_direction.normalized()) @ q
                break
        calibrated[i] = q
    times = [round(i / 30, 7) for i in range(last - first + 1)]
    tracks = {str(i): {'rotation': {'times': times, 'values': [], 'interpolation': 'LINEAR'}} for i in mapping}
    hip_values = []
    hips = [Vector(raw['frames'][i]['Hips']) for i in range(first - 1, last)]
    # Remove net advancing motion, preserve bounded centre-of-mass weight transfer.
    # Vertical placement uses the source standing bind height; falls retain their full descent.
    hip_ratio = target_pos('Hips').y / max(pos('Hips').z, .01)
    parent_rotation = rest(nodes[hip_index]['parent']).to_quaternion()
    for k, sample in enumerate(range(first - 1, last)):
        desired = {}
        def global_pose(i):
            if i not in desired:
                parent = nodes[i]['parent']
                if i in mapping:
                    name = mapping[i]
                    delta = quat(raw['rotations'][sample][name]) @ quat(bones[name]['rotation']).inverted()
                    desired[i] = align @ delta @ align.inverted() @ calibrated[i]
                else:
                    desired[i] = (global_pose(parent) if parent >= 0 else Quaternion()) @ quat(nodes[i]['rotation'])
            return desired[i]
        for i in range(len(nodes)): global_pose(i)
        for i in mapping:
            parent = nodes[i]['parent']
            local = (desired[parent].inverted() if parent >= 0 else Quaternion()) @ desired[i]
            values = tracks[str(i)]['rotation']['values']
            if values and quat(values[-1]).dot(local) < 0: local.negate()
            values.append(packed(local.normalized()))
        root = hips[k] - hips[0].lerp(hips[-1], k / (len(hips) - 1))
        root.z = hips[k].z - pos('Hips').z
        planar = Vector((root.x, root.y))
        if planar.length > .32:
            planar *= .32 / planar.length
            root.x, root.y = planar
        offset = parent_rotation.inverted() @ (align @ root * hip_ratio)
        hip_values.append([round(v, 7) for v in Vector(nodes[hip_index]['translation']) + offset])
    tracks[str(hip_index)]['translation'] = {'times': times, 'values': hip_values, 'interpolation': 'LINEAR'}
    if key == 'MX_Hurricane':
        # One complete source cycle needs an explicit entry/exit; it is not a ready-to-ready clip.
        guard = clips['MX_Roundhouse']['tracks']
        lead, tail = 6, 10
        for index, track in tracks.items():
            for channel, curve in track.items():
                values = curve['values']
                ready = guard[index][channel]['values'][0]
                def blend(a, b, weight):
                    return packed(quat(a).slerp(quat(b), weight)) if channel == 'rotation' else list(Vector(a).lerp(Vector(b), weight))
                before = [blend(ready, values[0], i / lead) for i in range(lead)]
                after = [blend(values[-1], ready, i / tail) for i in range(1, tail + 1)]
                curve['values'] = before + values + after
                curve['times'] = [round(i / 30, 7) for i in range(len(curve['values']))]
        times = tracks[str(hip_index)]['rotation']['times']
        hip_values = tracks[str(hip_index)]['translation']['values']
    clips[key] = {'duration': times[-1], 'tracks': tracks}
    markers[key] = {'contact': ((contact - first + (6 if key == 'MX_Hurricane' else 0)) / (len(times)-1)) if contact else .5, 'limb': limb}
    manifest.append({'clip': key, 'source': raw['name'], 'source_sha256': inspection[number]['sha256'],
                     'first_sample': first, 'last_sample': last, 'sample_rate': 30,
                     'contact_sample': contact, 'limb': limb, 'duration': times[-1],
                     'entry_blend_samples': 6 if key == 'MX_Hurricane' else 0,
                     'exit_blend_samples': 10 if key == 'MX_Hurricane' else 0})
    # Mirror in global rest-relative space, swapping limbs; local quaternion sign flips are insufficient.
    if key in ('MX_Roundhouse', 'MX_Hurricane'):
        reflection = Matrix.Diagonal((-1, 1, 1))
        swapped = {i: indices[nodes[i]['name'][:-2] + ('.R' if nodes[i]['name'].endswith('.L') else '.L')]
                   if nodes[i]['name'].endswith(('.L', '.R')) else i for i in range(len(nodes))}
        mirror_tracks = {str(i): {'rotation': {'times': times, 'values': [], 'interpolation': 'LINEAR'}} for i in mapping}
        for k in range(len(times)):
            globals_ = {}
            def posed(i):
                if i not in globals_:
                    parent = nodes[i]['parent']
                    local = quat(tracks[str(i)]['rotation']['values'][k]) if str(i) in tracks else quat(nodes[i]['rotation'])
                    globals_[i] = (posed(parent) if parent >= 0 else Quaternion()) @ local
                return globals_[i]
            mirrored = {}
            for i in range(len(nodes)):
                j = swapped[i]
                delta = posed(j) @ rest(j).to_quaternion().inverted()
                mirrored[i] = (reflection @ delta.to_matrix() @ reflection).to_quaternion() @ rest(i).to_quaternion()
            for i in mapping:
                parent = nodes[i]['parent']
                mirror_tracks[str(i)]['rotation']['values'].append(packed((mirrored[parent].inverted() if parent >= 0 else Quaternion()) @ mirrored[i]))
        # Reflect the root in global space as well.
        values = []
        for value in hip_values:
            delta = parent_rotation @ (Vector(value) - Vector(nodes[hip_index]['translation']))
            delta.x *= -1
            values.append(list(Vector(nodes[hip_index]['translation']) + parent_rotation.inverted() @ delta))
        mirror_tracks[str(hip_index)]['translation'] = {'times': times, 'values': values, 'interpolation': 'LINEAR'}
        clips[key + '_Mirror'] = {'duration': times[-1], 'tracks': mirror_tracks}
        markers[key + '_Mirror'] = dict(markers[key], limb='RightFoot')
        manifest.append(dict(manifest[-1], clip=key + '_Mirror', limb='RightFoot', mirrored=True))
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps({'schema': 1, 'kind': 'mixamo_fighters',
    'base_sha256': hashlib.sha256(base_path.read_bytes()).hexdigest(),
    'clips': clips, 'markers': markers, 'manifest': manifest}, separators=(',', ':')) + '\n')
output.chmod(0o600)
print(f'Built {len(clips)} game clips: {output} ({output.stat().st_size} bytes)')
