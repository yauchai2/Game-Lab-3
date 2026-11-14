"""Run with Blender and a private manifest of {path,file_id,filename} entries.
Only inspection.json metadata may enter the public repo; *-private-samples.json may not.
glTF stores seconds, not FPS; scene_fps is Blender's import timebase, not a file FPS claim.
"""
import bpy,json,hashlib,math,argparse,sys,os
from pathlib import Path
parser=argparse.ArgumentParser(description="Inspect user FBX/GLB motions; all pose samples remain private.")
inputs_group=parser.add_mutually_exclusive_group(required=True)
inputs_group.add_argument('--manifest',type=Path)
inputs_group.add_argument('--input-dir',type=Path,help='Directory of user-downloaded FBX/GLB files; order is immaterial')
parser.add_argument('--out-private',type=Path,required=True)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
root=args.out_private.resolve()
repo=Path(__file__).resolve().parents[1]
if root==repo or repo in root.parents:parser.error('Pose samples must be outside the public repository')
os.umask(0o077)
root.mkdir(parents=True,exist_ok=True)
inputs=json.loads(args.manifest.read_text()) if args.manifest else [
    {'path':str(p.resolve()),'file_id':'local','filename':p.name}
    for p in sorted(args.input_dir.expanduser().iterdir()) if p.suffix.lower() in ('.fbx','.glb')]
if not inputs:parser.error('No source FBX/GLB files found')
report=[]
for number,row in enumerate(inputs):
    src=Path(row['path'])
    bpy.ops.wm.read_factory_settings(use_empty=True)
    if src.suffix.lower()=='.fbx':bpy.ops.import_scene.fbx(filepath=str(src),use_anim=True)
    else:bpy.ops.import_scene.gltf(filepath=str(src))
    rigs=[o for o in bpy.data.objects if o.type=='ARMATURE']
    info={'filename':src.name,'file_id':row.get('file_id','local'),'bytes':src.stat().st_size,'sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'rigs':len(rigs),'actions':[]}
    for rig in rigs:
        info['bone_count']=len(rig.data.bones)
        info['bone_names']=[b.name for b in rig.data.bones]
        action=rig.animation_data.action if rig.animation_data else None
        if action is None:continue
        first,last=action.frame_range
        fps=bpy.context.scene.render.fps/bpy.context.scene.render.fps_base
        duration=(last-first)/fps
        frames=[]
        rotations=[]
        def rotation(matrix):
            q=matrix.to_quaternion().normalized()
            if q.w<0:q.negate()
            return [q.x,q.y,q.z,q.w]
        for k in range(round(duration*30)+1):
            t=min(duration,k/30)
            frame=first+t*fps
            bpy.context.scene.frame_set(int(frame),subframe=frame-int(frame))
            matrices={b.name:(rig.matrix_world@b.matrix) for b in rig.pose.bones}
            points={n.split(':')[-1].removeprefix('mixamorig_'):list(m.translation) for n,m in matrices.items()}
            frames.append(points)
            rotations.append({n.split(':')[-1].removeprefix('mixamorig_'):rotation(m) for n,m in matrices.items()})
        bones={b.name.split(':')[-1].removeprefix('mixamorig_'):{'parent':b.parent.name.split(':')[-1].removeprefix('mixamorig_') if b.parent else None,'position':list(rig.matrix_world@b.head_local),'rotation':rotation(rig.matrix_world@b.matrix_local)} for b in rig.data.bones}
        hip_name='Hips' if 'Hips' in frames[0] else next(iter(frames[0]))
        hips=[f[hip_name] for f in frames]
        semantic_hash=hashlib.sha256(json.dumps([{n:[round(v,5) for v in p] for n,p in f.items()} for f in frames],sort_keys=True).encode()).hexdigest()
        pose_hash=hashlib.sha256(json.dumps({'positions':[{n:[round(v,5) for v in p] for n,p in f.items()} for f in frames],'rotations':[{n:[round(v,5) for v in q] for n,q in f.items()} for f in rotations]},sort_keys=True).encode()).hexdigest()
        deltas=[math.dist(hips[i-1],hips[i]) for i in range(1,len(hips))]
        info['actions'].append({'semantic_pose_sha256':pose_hash,'hip_path_excluding_last_step_m':sum(deltas[:-1]),'closing_root_step_m':deltas[-1] if deltas else 0,'name':action.name,'scene_fps':fps,'frame_range':[first,last],'duration_seconds':duration,'samples_30fps':len(frames),'world_joint_semantic_sha256':semantic_hash,'hip_start':hips[0],'hip_end':hips[-1],'hip_net_distance_m':math.dist(hips[0],hips[-1]),'hip_bounds':[[min(p[i] for p in hips),max(p[i] for p in hips)] for i in range(3)]})
        (root/f'{number:02d}-private-samples.json').write_text(json.dumps({'name':src.name,'fps':30,'bones':bones,'frames':frames,'rotations':rotations}))
    report.append(info)
    print('INSPECT',src.name,info.get('bone_count'),[(a['duration_seconds'],a['frame_range']) for a in info['actions']],flush=True)
(root/'inspection.json').write_text(json.dumps(report,indent=2)+'\n')
