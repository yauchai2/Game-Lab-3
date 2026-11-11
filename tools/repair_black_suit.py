"""Blender: build a skinned, reversible neck/collar/tie repair from the untouched GLB.
Run: blender -b --python tools/repair_black_suit.py
"""
from pathlib import Path
import bpy, math, json, hashlib

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'godot/assets/characters/black_suit/source/tripo_convert_6bb9e9c2-dd66-4f86-864f-2ceab3aa0a09.glb'
OUTPUT=ROOT/'godot/assets/characters/black_suit/derived/black_suit_repaired.glb'
bpy.ops.wm.read_factory_settings(use_empty=True)
for obj in list(bpy.data.objects):bpy.data.objects.remove(obj,do_unlink=True)
bpy.ops.import_scene.gltf(filepath=str(SOURCE))
body=next(o for o in bpy.data.objects if o.type=='MESH' and len(o.data.vertices)==976)
rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
for obj in list(bpy.data.objects):
    if obj.type=='MESH' and obj!=body:bpy.data.objects.remove(obj,do_unlink=True)
original_hash=hashlib.sha256(SOURCE.read_bytes()).hexdigest()

def material(name,color):
    mat=bpy.data.materials.new(name);mat.diffuse_color=(*color,1);mat.use_nodes=True
    shader=mat.node_tree.nodes.get('Principled BSDF');shader.inputs['Base Color'].default_value=(*color,1);shader.inputs['Roughness'].default_value=.95
    body.data.materials.append(mat);return len(body.data.materials)-1

skin=material('Repair_NeckSkin',(.70,.55,.38))
shirt=material('Repair_WhiteShirt',(.94,.94,.91))
purple=material('Repair_PurpleTie',(.22,.035,.40))
# Original neck vertices have substantial shoulder influence. Remove that cross-pull.
reweighted=0
for v in body.data.vertices:
    if .835<v.co.z<.902 and abs(v.co.x)<.046:
        neck=sum(g.weight for g in v.groups if body.vertex_groups[g.group].name=='mixamorig:Neck')
        if neck>.3:
            for group in body.vertex_groups:group.remove([v.index])
            head=max(0,min(.45,(v.co.z-.855)*7))
            body.vertex_groups['mixamorig:Neck'].add([v.index],1-head,'REPLACE')
            body.vertex_groups['mixamorig:Head'].add([v.index],head,'REPLACE');reweighted+=1
# Replace the dark painted seam on the neck with a stable material region.
for face in body.data.polygons:
    center=sum((body.data.vertices[i].co for i in face.vertices),start=__import__('mathutils').Vector())/len(face.vertices)
    if .842<center.z<.895 and abs(center.x)<.033:face.material_index=skin

def patch(name,verts,faces,mat,weights):
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
    obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj)
    obj.data.materials.append(body.data.materials[mat])
    obj.parent=rig
    mod=obj.modifiers.new('Skin','ARMATURE');mod.object=rig
    for i,row in enumerate(weights):
        for bone,weight in row.items():
            group=obj.vertex_groups.get(bone) or obj.vertex_groups.new(name=bone);group.add([i],weight,'REPLACE')
    return obj

# An overlapping, closed eight-sided neck sleeve bridges the collar/head joint.
verts=[];weights=[]
for z,rx,ry,cy in [(.814,.026,.027,.031),(.85,.029,.032,.031),(.898,.029,.029,.025)]:
    for i in range(8):
        a=2*math.pi*i/8;verts.append((.001+rx*math.cos(a),cy+ry*math.sin(a),z))
        head=max(0,min(.45,(z-.855)*7));spine=.4 if z<.83 else 0
        weights.append({'mixamorig:Spine2':spine,'mixamorig:Neck':1-head-spine,'mixamorig:Head':head})
faces=[]
for ring in range(2):
    for i in range(8):
        a=ring*8+i;b=ring*8+(i+1)%8;c=b+8;d=a+8
        faces.extend([(a,b,c),(a,c,d)])
faces.extend([tuple(reversed(range(8))),tuple(range(16,24))])
patch('NeckBridge',verts,faces,skin,weights)

def cloth(name,points,mat):
    # Thin closed prism, avoiding single-sided loss when seen from side/back.
    verts=points+[(x,y+.002,z) for x,y,z in points];n=len(points)
    faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]
    faces.extend((i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n))
    return patch(name,verts,faces,mat,[{'mixamorig:Spine2':1.0} for _ in verts])
cloth('CleanShirtInsert',[(-.025,-.009,.811),(.025,-.009,.811),(.023,-.035,.748),(0,-.041,.725),(-.023,-.035,.748)],shirt)
cloth('TieKnot',[(-.009,-.015,.797),(.009,-.015,.797),(.011,-.022,.785),(0,-.028,.772),(-.011,-.022,.785)],purple)
cloth('TieBlade',[(-.005,-.029,.775),(.005,-.029,.775),(.009,-.048,.677),(0,-.051,.642),(-.009,-.048,.677)],purple)

for obj in bpy.context.selected_objects:obj.select_set(False)
for obj in bpy.data.objects:
    if obj.type in {'MESH','ARMATURE'}:obj.select_set(True)
OUTPUT.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.export_scene.gltf(filepath=str(OUTPUT),export_format='GLB',use_selection=True,export_animations=False,export_skins=True,export_yup=True,export_extras=False)
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==original_hash
report={'source_sha256':original_hash,'derived_sha256':hashlib.sha256(OUTPUT.read_bytes()).hexdigest(),'source':str(SOURCE.relative_to(ROOT)),'derived':str(OUTPUT.relative_to(ROOT)),'reweighted_neck_vertices':reweighted,'patches':['NeckBridge','CleanShirtInsert','TieKnot','TieBlade'],'method':'Skinned low-poly geometry and flat material repair; source GLB and original texture preserved. No image repaint or external generation.'}
(ROOT/'references/characters/black-suit/repair.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report))
