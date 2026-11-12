#!/usr/bin/env python3
"""Index byte-preserved user GLBs; no geometry or embedded texture mutation."""
from pathlib import Path
import struct,json,hashlib
ROOT=Path(__file__).resolve().parents[1]
FILES=[('ABILITY_DEALER_TRIPO','npc','tripo_convert_36d4f0c3-b64c-4ea1-841e-104fd70e96ae.glb',3.05),('ABILITY_CABINET_TRIPO','cabinet_shell','tripo_convert_275dc57f-e328-47e0-89e5-10195d3209c4.glb',2.0)]
records=[]
for asset_id,role,name,scale in FILES:
    path=ROOT/'godot/assets/ability_draw/source'/name;b=path.read_bytes()
    magic,version,length=struct.unpack_from('<III',b)
    assert magic==0x46546c67 and version==2 and length==len(b)
    size,kind=struct.unpack_from('<II',b,12);assert kind==0x4e4f534a
    j=json.loads(b[20:20+size]);vertices=0;triangles=0;bounds=[]
    for m in j.get('meshes',[]):
        for p in m['primitives']:
            a=j['accessors'][p['attributes']['POSITION']];vertices+=a['count'];triangles+=j['accessors'][p['indices']]['count']//3
            bounds.append({'min':a.get('min'),'max':a.get('max')})
    records.append({'asset_id':asset_id,'role':role,'path':str(path.relative_to(ROOT)),'original_filename':name,'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest(),'mesh_count':len(j.get('meshes',[])),'vertices':vertices,'triangles':triangles,'skin_count':len(j.get('skins',[])),'skin_joints':[len(s['joints']) for s in j.get('skins',[])],'animation_count':len(j.get('animations',[])),'bounds_in_source_units':bounds,'wrapper_uniform_scale':scale,'source':'User uploaded Tripo GLB; source bytes retained unchanged','runtime_motion':'Rest-relative CC0 gait plus authored two-bone contacts on original skin' if role=='npc' else 'Static shell under moving chassis; separate procedural drums, wheels, lever and hatch','runtime_import':'Godot 4 native glTF importer; embedded base color retained, wrapper cel material'})
report={'date':'2026-11-11','sources_preserved':True,'assets':records,'no_animation_in_source':True,'scope':'Metadata from the original binary files. Runtime movement is in Godot wrappers, not baked back into the source GLBs.'}
out=ROOT/'references/ability-draw/tripo/uploaded-models.json';out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
registry_path=ROOT/'assets-manifest.json';registry=json.loads(registry_path.read_text())
for r in records:
    entry={'asset_id':r['asset_id'],'model':r['path'],'triangles':r['triangles'],'bytes':r['bytes'],'sha256':r['sha256'],'status':'integrated_ability_draw_runtime','provenance':r['source'],'skeleton_bones':r['skin_joints'],'source_animation_count':r['animation_count'],'wrapper_scale':r['wrapper_uniform_scale']}
    existing=next((i for i,a in enumerate(registry['assets']) if a['asset_id']==r['asset_id']),None)
    if existing is None:registry['assets'].append(entry)
    else:registry['assets'][existing]=entry
registry_path.write_text(json.dumps(registry,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(report,ensure_ascii=False,indent=2))
