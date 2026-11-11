"""Inspect preserved user GLBs and record portable provenance. Not a game-dev receipt."""
from pathlib import Path
import hashlib, io, json, struct
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
FILES=[('1','file_00000000b54c82118597d128862622e1'),('3','file_000000009eb88207b6997de6f2b31445'),('4','file_00000000d050821185f2637b0649b76c')]
result=[]
for name,file_id in FILES:
    rel=f'godot/assets/characters/CHAR_FIGHTER_{name}.glb';raw=(ROOT/rel).read_bytes()
    magic,version,total=struct.unpack_from('<III',raw);assert magic==0x46546c67 and version==2 and total==len(raw)
    n,kind=struct.unpack_from('<II',raw,12);assert kind==0x4e4f534a
    doc=json.loads(raw[20:20+n]);offset=20+n;binary=b''
    while offset<len(raw):
        length,kind=struct.unpack_from('<II',raw,offset)
        if kind==0x004e4942:binary=raw[offset+8:offset+8+length]
        offset+=8+length
    assert len(binary)>=doc['buffers'][0]['byteLength']
    primitives=[p for m in doc['meshes'] for p in m['primitives']]
    assert all(p.get('mode',4)==4 for p in primitives)
    images=[]
    for im in doc.get('images',[]):
        view=doc['bufferViews'][im['bufferView']];start=view.get('byteOffset',0);content=binary[start:start+view['byteLength']]
        decoded=Image.open(io.BytesIO(content));decoded.load()
        images.append({'name':im.get('name'),'mime':im.get('mimeType'),'size':list(decoded.size),'sha256':hashlib.sha256(content).hexdigest()})
    bounds=[{'min':doc['accessors'][p['attributes']['POSITION']]['min'],'max':doc['accessors'][p['attributes']['POSITION']]['max']} for p in primitives]
    result.append({'asset_id':'CHAR_FIGHTER_'+name,'source_filename':name+'.glb','source_file_id':file_id,'model':rel,'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest(),'triangles':sum(doc['accessors'][p['indices']]['count']//3 for p in primitives),'mesh_count':len(doc['meshes']),'joint_counts':[len(s['joints']) for s in doc.get('skins',[])],'animation_count':len(doc.get('animations',[])),'materials':len(doc.get('materials',[])),'textures':images,'local_position_bounds':bounds,'runtime_scale':1.4 if name=='4' else 2.1,'provenance':'User supplied GLB in this conversation. No source rewrite or paid provider operation. No independent generator/license claim.','runtime_status':'Shared combat retargeting, original material base color with existing toon/outline overrides; no character-specific moves yet.'})
output=ROOT/'references/characters/uploads-2026-11-09.json';output.write_text(json.dumps({'inspection':'Python GLB binary/JSON/embedded image inspection; native validation is separate. game-dev CLI unavailable.','assets':result},ensure_ascii=False,indent=2)+'\n')
print(json.dumps([{k:a[k] for k in ['asset_id','triangles','joint_counts','animation_count']} for a in result]))
