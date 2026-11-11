"""Validate the preserved uploaded enemy GLB; keep provenance portable."""
from pathlib import Path
import hashlib
import io
import json
import math
import struct
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
REL = 'godot/assets/characters/black_suit/source/tripo_convert_6bb9e9c2-dd66-4f86-864f-2ceab3aa0a09.glb'
raw = (ROOT / REL).read_bytes()
magic, version, size = struct.unpack_from('<III', raw)
assert magic == 0x46546C67 and version == 2 and size == len(raw)
length, kind = struct.unpack_from('<II', raw, 12)
assert kind == 0x4E4F534A
doc = json.loads(raw[20:20 + length])
offset = 20 + length
binary = b''
while offset < len(raw):
    length, kind = struct.unpack_from('<II', raw, offset)
    if kind == 0x004E4942:
        binary = raw[offset + 8:offset + 8 + length]
    offset += 8 + length

def accessor(index):
    a = doc['accessors'][index]
    view = doc['bufferViews'][a['bufferView']]
    count = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}[a['type']]
    code = {5121: 'B', 5123: 'H', 5125: 'I', 5126: 'f'}[a['componentType']]
    fmt = '<' + code * count
    start = view.get('byteOffset', 0) + a.get('byteOffset', 0)
    stride = view.get('byteStride', struct.calcsize(fmt))
    return [struct.unpack_from(fmt, binary, start + i * stride) for i in range(a['count'])]

primitives = [p for mesh in doc['meshes'] for p in mesh['primitives']]
assert all(p.get('mode', 4) == 4 for p in primitives)
joint_count = len(doc['skins'][0]['joints'])
weight_error = 0.0
for p in primitives:
    for attr in ['POSITION', 'NORMAL', 'TEXCOORD_0', 'WEIGHTS_0']:
        assert all(math.isfinite(v) for row in accessor(p['attributes'][attr]) for v in row)
    assert all(0 <= v < joint_count for row in accessor(p['attributes']['JOINTS_0']) for v in row)
    for row in accessor(p['attributes']['WEIGHTS_0']):
        assert all(v >= 0 for v in row)
        weight_error = max(weight_error, abs(sum(row) - 1))
    assert weight_error < 0.001
    positions = accessor(p['attributes']['POSITION'])
    assert all(row[0] < len(positions) for row in accessor(p['indices']))
for skin in doc['skins']:
    assert all(math.isfinite(v) for row in accessor(skin['inverseBindMatrices']) for v in row)
textures = []
for image in doc['images']:
    view = doc['bufferViews'][image['bufferView']]
    start = view.get('byteOffset', 0)
    content = binary[start:start + view['byteLength']]
    decoded = Image.open(io.BytesIO(content))
    decoded.load()
    textures.append({'size': list(decoded.size), 'sha256': hashlib.sha256(content).hexdigest(), 'mime': image['mimeType']})
report = {'asset_id': 'black_suit', 'source_filename': Path(REL).name,
          'source_file_id': 'file_00000000771c8211be654cfe36574a77',
          'source_uuid': '6bb9e9c2-dd66-4f86-864f-2ceab3aa0a09',
          'model': REL, 'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest(),
          'triangles': sum(doc['accessors'][p['indices']]['count'] // 3 for p in primitives),
          'vertices': sum(doc['accessors'][p['attributes']['POSITION']]['count'] for p in primitives),
          'joints': joint_count, 'animations': len(doc.get('animations', [])),
          'mesh_count': len(doc['meshes']), 'textures': textures,
          'max_weight_sum_error': weight_error,
          'bounds': [doc['accessors'][p['attributes']['POSITION']] for p in primitives],
          'runtime_scale': 2.15, 'visual_index': 4,
          'provenance': 'User-uploaded Tripo GLB preserved byte-for-byte. No paid generation, source edits or new licensing claim.',
          'validation_scope': 'Binary GLB, finite vertices/normals/UV/weights/binds, weight sums, joint/index bounds and embedded texture decoding. Native rendering and animation checks are separate.'}
out = ROOT / 'references/characters/black-suit/inspection.json'
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print(json.dumps({key: report[key] for key in ['triangles', 'vertices', 'joints', 'animations', 'sha256']}))
