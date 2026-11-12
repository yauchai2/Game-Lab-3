"""Original low-poly campaign models. Run: blender -b --python tools/build_campaign_models.py -- <repo>"""
import bpy, math, sys
from pathlib import Path
from mathutils import Vector
ROOT=Path(sys.argv[sys.argv.index('--')+1]) if '--' in sys.argv else Path.cwd()
OUT=ROOT/'godot/assets/campaign/generated';OUT.mkdir(parents=True,exist_ok=True)
COLORS={'ink':(.035,.035,.065,1),'paper':(.83,.83,.87,1),'grey':(.18,.19,.26,1),'blue':(.02,.73,.83,1),'pink':(.96,.015,.37,1),'gold':(.93,.56,.10,1),'green':(.57,.72,.13,1)}
def reset():
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 for mat in list(bpy.data.materials):bpy.data.materials.remove(mat)
 global mats;mats={}
 for name,color in COLORS.items():
  mat=bpy.data.materials.new(name);mat.diffuse_color=color;mat.use_nodes=True
  node=mat.node_tree.nodes.get('Principled BSDF');node.inputs['Base Color'].default_value=color;node.inputs['Roughness'].default_value=1;mats[name]=mat

def box(name,at,scale,mat,parent=None):
 bpy.ops.mesh.primitive_cube_add(size=1,location=at);o=bpy.context.object;o.name=name;o.scale=scale
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mats[mat])
 if parent:o.parent=parent
 return o

def orb(name,at,radius,mat,parent=None):
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=radius,location=at);o=bpy.context.object;o.name=name;o.data.materials.append(mats[mat])
 if parent:o.parent=parent
 return o

def joint(name,at):
 o=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(o);o.location=at;return o

def export(name):
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',export_yup=True,export_animations=False,export_cameras=False,export_lights=False)

def boss(final):
 reset();height=5.1 if final else 4.3
 torso=box('Torso',(0,0,height*.58),(2.25,1.8,1.6),'ink' if final else 'gold')
 for side in [-1,1]:
  x=side*.65
  box('Foot_'+str(side),(x,-.12,.26),(.8,1.65,.5),'grey' if final else 'ink')
  box('Shin_'+str(side),(x,0,.95),(.65,.82,1.1),'paper')
  orb('Knee_'+str(side),(x,-.45,1.5),.38,'pink' if final else 'gold')
  box('Thigh_'+str(side),(x,0,1.83),(.8,.8,.75),'paper')
  pivot=joint('Arm_L' if side<0 else 'Arm_R',(side*1.5,0,height*.71))
  box('Shoulder',(0,0,0),(.9,1.3,.7),'paper' if final else 'gold',pivot)
  box('UpperArm',(0,0,-.65),(.6,.7,.9),'grey',pivot)
  box('Piston',(0,.05,-1.15),(.35,.4,.9),'blue',pivot)
  box('Hammer',(0,-.15,-1.55),(1.0,1.0,.7),'pink' if final else 'gold',pivot)
  for i in range(3):box('ArmStripe',(0,-.67+i*.16,-1.55),(.8,.06,.18),'ink',pivot)
 head=joint('HeadPivot',(0,0,height-.6))
 box('Helmet',(0,0,0),(1.4,1.2,.9),'paper' if final else 'ink',head)
 box('Visor',(0,-.63,0),(1.05,.08,.22),'pink' if final else 'blue',head)
 core=joint('CorePivot',(0,-.72,height*.57));orb('Core', (0,0,0),.55,'pink' if final else 'blue',core)
 for x in [-.9,.9]:box('ChestCage',(x,-.75,height*.56),(.18,.18,1.1),'paper')
 if final:
  for x in [-.7,0,.7]:
   box('Antenna',(x,.1,height+.1),(.13,.15,1.25-abs(x)*.5),'ink')
   orb('SignalBulb',(x,.1,height+.75-abs(x)*.2),.17,'pink')
  for i in range(5):box('DorsalFin',(0,.9,height*.4+i*.35),(1.2-i*.12,.7,.14),'paper')
 else:
  for x in [-.8,.8]:box('CargoPack',(x,.95,2.7),(.65,.8,2.4),'grey')
 export('signal_leviathan' if final else 'gantry_warden')

def district(index):
 reset();accent=['blue','green','blue','gold','pink','pink'][index]
 box('ArenaFloor',(0,-1.5,-.15),(32,23,.3),'grey')
 box('FightLane',(0,-3,.01),(22,3,.04),'ink')
 for x in range(-10,11,2):box('RoadDash',(x,-3,.05),(.9,.16,.05),'paper')
 for side in [-1,1]:
  box('Sidewalk',(side*11,0,.22),(2.8,20,.4),'paper')
  for i in range(5):
   x=side*(10.5+(i%2)*1.2);y=3+i*2.8;h=5+(i*3+index)%5
   box('Building',(x,y,h/2),(3.6,2.5,h),'ink' if i%2 else 'grey')
   for z in range(1,h):box('WindowStrip',(x-side*1.85,y,z),(.06,1.8,.18),'paper' if z%3 else accent)
 for x in [-7,7]:
  box('Lamp',(x,1,2.5),(.14,.14,5),'ink');box('LampBar',(x,1,4.9),(1.5,.22,.2),accent)
 if index==0:
  for x in [-5,5]:
   for i in range(3):box('ShopShutter',(x,2,1.5+i*.22),(2,.18,.10),'paper')
  for i in range(6):box('OverheadWire',(-7+i*2.8,4,5.8),(.04,8,.04),'ink')
 elif index==1:
  for x in [-8,8]:box('GatePillar',(x,1,2.7),(1,1,5.4),'ink')
  box('GateHeader',(0,1,5.4),(17,1,.6),accent)
  for x in range(-7,8,2):box('ClosedGate',(x,5,2.3),(.12,.25,4.6),'paper')
 elif index==2:
  for x in [-8,-4,4,8]:box('BridgePillar',(x,3,3),(1,1.5,6),'paper')
  box('Flyover',(0,3,6.3),(29,6,.7),'ink')
  for x in range(-10,11,2):box('BridgeLamp',(x,1,5.8),(.8,.4,.12),accent)
 elif index==3:
  for side in [-1,1]:
   for layer in range(2):
    box('Container',(side*6.5,3,1.1+2.2*layer),(4,2.5,2),accent if layer else 'ink')
    for rib in range(9):box('Rib',(side*6.5-1.6+rib*.4,1.7,1.1+2.2*layer),(.05,.08,1.8),'paper')
  box('CraneMast',(-9,6,4),(.5,.5,8),'gold');box('CraneBeam',(-3,6,7.8),(13,.5,.5),'gold')
 elif index==4:
  for x in [-8,-6,6,8]:
   box('RoadBarrier',(x,1,.55),(1.4,.7,1.1),'paper');box('WarningStripe',(x,.61,.55),(1.25,.05,.26),accent)
  for x in [-7,7]:
   box('Speaker',(x,4,2),(1.4,1.0,3.5),'ink');orb('Siren',(x,4,4),.35,accent)
 else:
  for x in [-6,6]:
   box('TowerSpire',(x,5,5),(2.2,3.5,10),'ink');box('SpireCurrent',(x,3.2,5),(.2,.08,9),accent)
  for h in [4.5,6.5,8.5]:box('SignalBridge',(0,6,h),(14,.7,.18),'paper')
  orb('BackgroundTransmitter',(0,7,6.5),2.3,accent)
 export('district_'+str(index))
for final in [False,True]:boss(final)
for index in range(6):district(index)
print('CAMPAIGN_MODELS_BUILT',OUT)
def npc(name,coat,accessory):
 reset()
 box('Coat',(0,0,.85),(.58,.38,.85),coat)
 for side in [-1,1]:
  box('Boot',(side*.17,-.05,.16),(.24,.4,.3),'ink')
  box('Leg',(side*.16,0,.42),(.2,.24,.45),'grey')
  box('Sleeve',(side*.39,0,1.0),(.2,.3,.65),coat)
  box('Hand',(side*.39,-.03,.65),(.16,.2,.18),'paper')
 box('Head',(0,0,1.52),(.44,.4,.44),'ink');box('Visor',(0,-.21,1.52),(.30,.04,.12),'blue')
 if accessory=='cap':box('Cap',(0,-.08,1.76),(.60,.65,.12),'gold')
 if accessory=='antenna':box('RadioAntenna',(.28,.18,1.65),(.04,.04,.65),'paper')
 if accessory=='tool':box('ToolRoll',(.40,-.1,.62),(.25,.35,.45),'gold')
 export(name)
for args in [('city_keeper','paper','antenna'),('city_dealer','pink','cap'),('city_mechanic','green','tool')]:npc(*args)
reset()
box('SafeFloor',(0,0,-.2),(18,17,.4),'grey')
for x in range(-8,9,2):
 for y in range(-8,9,2):box('Paving',(x,y,.02),(1.92,1.92,.04),'ink' if (x+y)%4==0 else 'grey')
for x in [-6,-2,2,6]:
 h=4+(int(x)%3);box('SafeBuilding',(x,7,h/2),(3.5,1.8,h),'ink')
 for z in range(1,h):box('SafeWindow',(x,6.05,z),(2.4,.06,.15),'paper')
for i,(x,y) in enumerate([(-5,0),(-3,4),(2,4),(5,0),(1,-4)]):
 col=['blue','green','pink','gold','paper'][i]
 box('StationBase',(x,y,.15),(2,.0+1.7,.3),col)
 if i==4:
  for side in [-1,1]:box('ExitPillar',(x+side*.8,y,1.4),(.22,.3,2.5),'paper')
  box('ExitCurrent',(x,y,2.7),(1.9,.3,.2),'pink')
 else:
  box('StationDesk',(x,y,.70),(1.25,.7,1.1),'ink');box('Console',(x,y,1.4),(1.2,.3,.5),col)
for x,y in [(-6,-5.5),(6,-5.5),(-6,5.7)]:
 box('Planter',(x,y,.3),(1.5,1.5,.6),'paper');orb('Plant',(x,y,1.1),.8,'green')
for x in [-8,8]:
 box('SafeLamp',(x,0,2.6),(.16,.16,5.2),'paper');box('LampCurrent',(x,0,5.2),(.5,.5,.3),'blue')
export('safe_block')
