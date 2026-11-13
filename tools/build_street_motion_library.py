"""Retarget pinned CC0 GLB motion clips onto the existing canonical JSON rig.

Requires numpy/scipy. Arguments: UAL2.glb KayKit_CombatMelee.glb
KayKit_MovementBasic.glb KayKit_MovementAdvanced.glb. No meshes are emitted.
Source locations/hashes are in references/animation-sources/street-library.json.
"""
import hashlib
import json
from pathlib import Path
import struct
import sys
import numpy as np
from scipy.spatial.transform import Rotation as R, Slerp

ROOT = Path(__file__).resolve().parents[1]
PROVENANCE = json.loads((ROOT / 'references/animation-sources/street-library.json').read_text())
canonical_path=ROOT / PROVENANCE['canonical_file']
assert hashlib.sha256(canonical_path.read_bytes()).hexdigest()==PROVENANCE['canonical_sha256'], 'Canonical library hash mismatch'
CANON = json.loads(canonical_path.read_text())
I = R.identity()

def glb(path):
    b = Path(path).read_bytes()
    if b[:4] != b'glTF':
        raise ValueError('Expected a binary glTF file')
    size = struct.unpack_from('<I', b, 12)[0]
    doc = json.loads(b[20:20+size])
    binary = b[28+size:]
    return doc, binary

def read(doc, binary, index):
    a = doc['accessors'][index]
    assert a['componentType'] == 5126 and not a.get('sparse')
    v = doc['bufferViews'][a['bufferView']]
    width = {'SCALAR': 1, 'VEC3': 3, 'VEC4': 4}[a['type']]
    start = v.get('byteOffset', 0) + a.get('byteOffset', 0)
    stride = v.get('byteStride', width*4)
    return np.array([struct.unpack_from('<'+'f'*width, binary, start+i*stride) for i in range(a['count'])])

def globals_for(nodes, rotations, translations):
    rotations_global, positions = {}, {}
    def visit(index):
        if index in rotations_global:
            return rotations_global[index], positions[index]
        parent = nodes[index]['parent']
        pr, pp = visit(parent) if parent >= 0 else (I, np.zeros(3))
        rotations_global[index] = pr*rotations[index]
        positions[index] = pp+pr.apply(translations[index])
        return rotations_global[index], positions[index]
    for index in range(len(nodes)):
        visit(index)
    return rotations_global, positions

def rest(nodes):
    rotations = [R.from_quat(n.get('rotation', [0,0,0,1])) for n in nodes]
    translations = [np.array(n.get('translation', [0,0,0]), float) for n in nodes]
    return rotations, translations, globals_for(nodes, rotations, translations)

def frame(positions, names, keys):
    right, left, head, hips = [positions[names[k]] for k in keys]
    y = head-hips; y /= np.linalg.norm(y)
    x = right-left; x -= y*np.dot(x,y); x /= np.linalg.norm(x)
    return R.from_matrix(np.column_stack((x,y,np.cross(x,y))))

NODES = CANON['nodes']
TR, TT, (TG, TP) = rest(NODES)
TN = {n['name']: i for i,n in enumerate(NODES)}
TF = frame(TP, TN, ['DEF-upper_arm.R','DEF-upper_arm.L','DEF-head','DEF-hips'])
BASE = {'DEF-hips':'pelvis','DEF-spine.001':'spine_01','DEF-spine.002':'spine_02',
        'DEF-spine.003':'spine_03','DEF-neck':'neck_01','DEF-head':'Head'}
KAY = {'DEF-hips':'hips','DEF-spine.001':'spine','DEF-spine.002':'chest','DEF-spine.003':'chest','DEF-head':'head'}
for side in ('L','R'):
    low=side.lower()
    for target,source in [('shoulder','clavicle'),('upper_arm','upperarm'),('forearm','lowerarm'),('hand','hand'),('thigh','thigh'),('shin','calf'),('foot','foot'),('toe','ball')]:
        BASE[f'DEF-{target}.{side}']=f'{source}_{low}'
    for target,source in [('upper_arm','upperarm'),('forearm','lowerarm'),('hand','hand'),('thigh','upperleg'),('shin','lowerleg'),('foot','foot'),('toe','toes')]:
        KAY[f'DEF-{target}.{side}']=f'{source}.{low}'
    for target,source in [('thumb','thumb'),('f_index','index'),('f_middle','middle'),('f_ring','ring'),('f_pinky','pinky')]:
        for digit in range(1,4):BASE[f'DEF-{target}.0{digit}.{side}']=f'{source}_0{digit}_{low}'

SOURCES = [
    ('ual2',BASE,{'Melee_Hook':'UAL2_Hook','Melee_Hook_Rec':'UAL2_Hook_Rec'}),
    ('kay_melee',KAY,{'Melee_Unarmed_Attack_Kick':'KK_Kick','Melee_Unarmed_Idle':'KK_Guard','Melee_Unarmed_Attack_Punch_A':'KK_Punch'}),
    ('kay_basic',KAY,{'Walking_A':'KK_Walk','Running_A':'KK_Run'}),
    ('kay_advanced',KAY,{'Walking_Backwards':'KK_Backstep','Dodge_Backward':'KK_DodgeBack','Dodge_Forward':'KK_DodgeForward'})]
result={'schema':1,'license':'CC0-1.0','canonical_nodes_sha256':hashlib.sha256(json.dumps(NODES,separators=(',',':')).encode()).hexdigest(),'clips':{},'markers':{}}
raw_hashes={}
for path,(source_key,mapping,selected) in zip(sys.argv[1:],SOURCES,strict=True):
    doc,binary=glb(path)
    raw_hashes[source_key]=hashlib.sha256(Path(path).read_bytes()).hexdigest()
    assert raw_hashes[source_key]==PROVENANCE['sources'][source_key]['sha256'], 'Source hash mismatch: '+source_key
    parents={child:i for i,n in enumerate(doc['nodes']) for child in n.get('children',[])}
    nodes=[dict(n,parent=parents.get(i,-1)) for i,n in enumerate(doc['nodes'])]
    SR,ST,(SG,SP)=rest(nodes); SN={n.get('name',''):i for i,n in enumerate(nodes)}
    pairs={TN[t]:SN[s] for t,s in mapping.items() if t in TN and s in SN}
    sf=frame(SP,SN,[mapping[n] for n in ['DEF-upper_arm.R','DEF-upper_arm.L','DEF-head','DEF-hips']])
    align=TF*sf.inv()
    scale=np.linalg.norm(TP[TN['DEF-head']]-TP[TN['DEF-hips']])/np.linalg.norm(SP[SN[mapping['DEF-head']]]-SP[SN[mapping['DEF-hips']]])
    for animation in doc['animations']:
        if animation['name'] not in selected:continue
        clip_name=selected[animation['name']];channels=[];duration=0
        for ch in animation['channels']:
            kind=ch['target']['path']
            if kind not in ['rotation','translation']:continue
            sampler=animation['samplers'][ch['sampler']]
            assert sampler.get('interpolation','LINEAR') in ['LINEAR','STEP']
            times=read(doc,binary,sampler['input']).ravel();values=read(doc,binary,sampler['output'])
            duration=max(duration,float(times[-1]));channels.append((ch['target']['node'],kind,times,values,sampler.get('interpolation','LINEAR')))
        times=np.linspace(0,duration,round(duration*60)+1)
        tracks={str(t):{'rotation':{'times':times.round(6).tolist(),'values':[]}} for t in pairs}
        hip=TN['DEF-hips'];tracks[str(hip)]['translation']={'times':times.round(6).tolist(),'values':[]}
        limbs={name:[] for name in ['DEF-hand.L','DEF-hand.R','DEF-foot.L','DEF-foot.R']}
        for time in times:
            rotations=SR.copy();translations=ST.copy()
            for index,kind,kt,values,interpolation in channels:
                if kind=='rotation':
                    if interpolation=='STEP':rotation=R.from_quat(values[max(0,np.searchsorted(kt,time,side='right')-1)])
                    else:rotation=Slerp(kt,R.from_quat(values))([min(float(time),float(kt[-1]))])[0]
                    rotations[index]=rotation
                else:translations[index]=np.array([np.interp(time,kt,values[:,axis]) for axis in range(3)])
            pg,pp=globals_for(nodes,rotations,translations);desired={}
            def convert(t):
                if t in desired:return desired[t]
                parent=NODES[t]['parent'];pr=convert(parent) if parent>=0 else I
                if t in pairs:
                    s=pairs[t];desired[t]=align*(pg[s]*SG[s].inv())*align.inv()*TG[t]
                    q=(pr.inv()*desired[t]).as_quat()
                    # Keep adjacent quaternion signs continuous.
                    previous=tracks[str(t)]['rotation']['values']
                    if previous and np.dot(q,previous[-1])<0:q=-q
                    previous.append(q.round(6).tolist())
                else:desired[t]=pr*TR[t]
                return desired[t]
            for t in range(len(NODES)):convert(t)
            delta=align.apply(pp[pairs[hip]]-SP[pairs[hip]])*scale
            delta=TG[NODES[hip]['parent']].inv().apply(delta)
            tracks[str(hip)]['translation']['values'].append((TT[hip]+delta).round(6).tolist())
            front=-TF.as_matrix()[:,2]
            for limb in limbs:
                limbs[limb].append(float(np.dot(align.apply(pp[pairs[TN[limb]]]-pp[pairs[hip]]),front)))
        candidates=['DEF-foot.L','DEF-foot.R'] if 'Kick' in clip_name else ['DEF-hand.L','DEF-hand.R']
        chosen=max(candidates,key=lambda key:max(limbs[key])-min(limbs[key]))
        contact=int(np.argmax(np.abs(np.array(limbs[chosen])-limbs[chosen][0])))
        result['clips'][clip_name]={'duration':round(duration,6),'tracks':tracks}
        result['markers'][clip_name]={'source':animation['name'],'limb':chosen,'contact':round(float(times[contact]/duration),6),'mapped_bones':len(pairs)}
        print(clip_name,result['markers'][clip_name])
# Reflect the entire kick across the anatomical sagittal plane, including hips.
# Reflect rotation deltas (not raw Euler angles), then rebuild local rotations.
original=result['clips']['KK_Kick']
mirror=json.loads(json.dumps(original))
reflection=TF.as_matrix()@np.diag([-1.0,1.0,1.0])@TF.as_matrix().T
for sample in range(len(original['tracks'][str(TN['DEF-hips'])]['rotation']['times'])):
    rotations=TR.copy()
    for key,track in original['tracks'].items():rotations[int(key)]=R.from_quat(track['rotation']['values'][sample])
    pose,_positions=globals_for(NODES,rotations,TT);desired={}
    def mirrored(t):
        if t in desired:return desired[t]
        parent=NODES[t]['parent'];pr=mirrored(parent) if parent>=0 else I
        if str(t) not in mirror['tracks']:
            desired[t]=pr*TR[t]
        else:
            name=NODES[t]['name']
            other=TN.get(name[:-2]+('.R' if name.endswith('.L') else '.L'),t) if name.endswith(('.L','.R')) else t
            delta=pose[other]*TG[other].inv()
            desired[t]=R.from_matrix(reflection@delta.as_matrix()@reflection)*TG[t]
            mirror['tracks'][str(t)]['rotation']['values'][sample]=(pr.inv()*desired[t]).as_quat().round(6).tolist()
        return desired[t]
    for t in range(len(NODES)):mirrored(t)
    hip=TN['DEF-hips'];parent=NODES[hip]['parent']
    offset=np.array(original['tracks'][str(hip)]['translation']['values'][sample])-TT[hip]
    mirror['tracks'][str(hip)]['translation']['values'][sample]=(TT[hip]+TG[parent].inv().apply(reflection@TG[parent].apply(offset))).round(6).tolist()
result['clips']['KK_Kick_Mirror']=mirror
result['markers']['KK_Kick_Mirror']=dict(result['markers']['KK_Kick'],limb='DEF-foot.L',derivation='Whole-body anatomical reflection')
out=ROOT/'godot/assets/animations/street_library.json'
out.write_text(json.dumps(result,separators=(',',':'))+'\n')
print('SOURCE_HASHES',json.dumps(raw_hashes));print('DERIVED_SHA256',hashlib.sha256(out.read_bytes()).hexdigest())
