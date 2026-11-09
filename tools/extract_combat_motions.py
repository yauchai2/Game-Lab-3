"""Extract a bounded CC0 animation subset; no character mesh is redistributed.
Input: pinned Quaternius Standard glTF + bin, downloaded from the recorded mirror.
Usage: python3 tools/extract_combat_motions.py /tmp/quaternius-animations
"""
import hashlib,json,pathlib,struct,sys
src=pathlib.Path(sys.argv[1]); doc=json.loads((src/'AnimationLibrary_Godot_Standard.gltf').read_text()); binary=(src/'AnimationLibrary_Godot_Standard.bin').read_bytes()
selected=['Punch_Enter','Punch_Jab','Punch_Cross','Hit_Chest','Hit_Head','Walk_Loop','Jog_Fwd_Loop','Sprint_Loop','Jump_Start','Jump_Loop','Jump_Land','Roll','Death01','Spell_Simple_Shoot','Dance_Loop','Crouch_Idle_Loop','Spell_Simple_Idle_Loop','Sword_Attack','Idle_Loop']
def read(index):
 a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']];n={'SCALAR':1,'VEC3':3,'VEC4':4}[a['type']]; stride=v.get('byteStride',n*4);offset=v.get('byteOffset',0)+a.get('byteOffset',0)
 rows=[list(struct.unpack_from('<'+'f'*n,binary,offset+i*stride)) for i in range(a['count'])]
 return [[round(x,6) for x in row] for row in rows] if n>1 else [round(row[0],6) for row in rows]
parents={child:i for i,node in enumerate(doc['nodes']) for child in node.get('children',[])}
nodes=[{'name':node.get('name',''), 'parent':parents.get(i,-1),'rotation':node.get('rotation',[0,0,0,1]),'translation':node.get('translation',[0,0,0])} for i,node in enumerate(doc['nodes'])]
result={'author':'Quaternius','license':'CC0-1.0','nodes':nodes,'clips':{}}
for anim in doc['animations']:
 if anim['name'] not in selected:continue
 clip={'duration':0,'tracks':{}}
 for channel in anim['channels']:
  target=channel['target'];node=target['node'];kind=target['path']
  if kind!='rotation' and not (kind=='translation' and nodes[node]['name']=='DEF-hips'):continue
  sampler=anim['samplers'][channel['sampler']];times=read(sampler['input']);values=read(sampler['output'])
  clip['duration']=max(clip['duration'],times[-1]);track=clip['tracks'].setdefault(str(node),{})
  track[kind]={'times':times,'values':values,'interpolation':sampler.get('interpolation','LINEAR')}
 result['clips'][anim['name']]=clip
out=pathlib.Path('godot/assets/animations');out.mkdir(parents=True,exist_ok=True)
p=out/'quaternius_combat.json';p.write_text(json.dumps(result,separators=(',',':'))+'\n')
(out/'LICENSE-Quaternius.txt').write_bytes((src/'LICENSE').read_bytes())
metadata={'author':'Quaternius','license':'CC0-1.0','official_page':'https://quaternius.com/packs/universalanimationlibrary.html','mirror':'https://github.com/J-Ponzo/gltf-universal-animation-library','commit':'e24c23cf2a1323488a3faa226ea7ea21f644b73e','clips':selected,'raw_sha256':{name:hashlib.sha256((src/name).read_bytes()).hexdigest() for name in ['AnimationLibrary_Godot_Standard.gltf','AnimationLibrary_Godot_Standard.bin','LICENSE']},'derived_file':str(p),'derived_sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'derivation':'Selected rotation tracks and hip translations, 6 decimal places; meshes omitted. Runtime retargets rest-relative rotations onto user Mixamo skeleton. No paid or Mixamo account download used.'}
pathlib.Path('references/animation-sources/quaternius.json').write_text(json.dumps(metadata,indent=2)+'\n')
print(len(result['clips']),'clips,',p.stat().st_size,'bytes')
