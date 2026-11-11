"""Render the exact Godot-exported S1 geometry using Blender CPU (not a Godot capture).
Run after verify_whitebox.gd exports the temporary GLB:
  blender --background --python tools/render_whitebox_previews.py
"""
import bpy,json,sys,math,tempfile
from pathlib import Path
from mathutils import Vector
repo=Path(__file__).resolve().parents[1]
source=Path(tempfile.gettempdir())/'flight-street-whitebox.glb'
out=repo/'docs/evidence/whitebox';out.mkdir(parents=True,exist_ok=True)
config=json.loads((repo/'godot/config/street_whitebox.json').read_text())
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(source))
scene=bpy.context.scene
for obj in list(scene.objects):
 if obj.type in ['LIGHT','CAMERA']:bpy.data.objects.remove(obj,do_unlink=True)
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=24;scene.cycles.use_denoising=False
scene.render.resolution_x=800;scene.render.resolution_y=800;scene.render.resolution_percentage=100
scene.view_settings.view_transform='Standard'
scene.world=bpy.data.worlds.new('PreviewSky');scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(0.49,0.73,0.88,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.65
bpy.ops.object.light_add(type='SUN',location=(0,0,50));sun=bpy.context.object;sun.data.energy=2.0;sun.data.angle=.06;sun.rotation_euler=(math.radians(30),math.radians(-25),math.radians(-25))
bpy.ops.object.camera_add();camera=bpy.context.object;scene.camera=camera
camera.data.clip_end=800
preview_info=[]
def convert(values):return Vector((values[0],-values[2],values[1]))
for item in config['cameras']:
 camera.location=convert(item['position']);target=convert(item['target'])
 camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
 if 'orthographic_size' in item:
  camera.data.type='ORTHO';camera.data.ortho_scale=item['orthographic_size']
 else:
  camera.data.type='PERSP';camera.data.sensor_fit='VERTICAL';camera.data.sensor_height=32;camera.data.lens=32/(2*math.tan(math.radians(item['fov'])/2))
 for obj in scene.objects:
  if obj.type=='MESH' and 'Aircraft_' in obj.name:obj.hide_render='orthographic_size' in item
 file=out/f'{item["id"]}.png';scene.render.filepath=str(file);bpy.ops.render.render(write_still=True)
 preview_info.append({'id':item['id'],'image':file.name,'camera_position_godot':item['position'],'camera_target_godot':item['target'],'renderer':'Blender Cycles CPU','same_godot_geometry':True,'lighting_matches_godot':False,'godot_gpu_capture':False})
 print('WHITEBOX_PREVIEW_DONE',item['id'],flush=True)
(out/'previews.json').write_text(json.dumps(preview_info,ensure_ascii=False,indent=2))
