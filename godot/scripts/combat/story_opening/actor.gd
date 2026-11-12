extends Node3D
## Cinematic performer for the story opening. Wraps the existing roster visual
## (original GLBs untouched) and samples the shared CC0 clips statelessly, then
## layers authored limb aims / two-bone reaches. No AI, damage, input or save data.
const Visual=preload("res://scripts/combat/fighter_visual.gd")
const Contact=preload("res://scripts/combat/ability_draw/dealer_rig.gd")
var visual:Node3D
var solver:Node3D
var index:=0
var shadow:MeshInstance3D

func setup(character:int) -> void:
	index=character
	visual=Visual.new();visual.name="Visual";visual.neon_enabled=true;add_child(visual)
	visual.setup(Color.WHITE,character)
	var baton:Node=visual.find_child("SignalBaton",true,false)
	if baton!=null:baton.hide()
	solver=Contact.new();solver.name="Reach";add_child(solver)
	solver.model=visual.model;solver.skeleton=visual.skeleton;solver.motions=visual.motions
	shadow=MeshInstance3D.new()
	var disc:=CylinderMesh.new();disc.top_radius=.5;disc.bottom_radius=.5;disc.height=.012;disc.radial_segments=10
	var ink:=StandardMaterial3D.new();ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;ink.albedo_color=Color("1c1826")
	shadow.mesh=disc;shadow.material_override=ink;shadow.top_level=true;add_child(shadow)

func place(at:Vector3,heading_degrees:float) -> void:
	# Heading 0 faces +Z (out of the garage door); positive turns toward +X.
	position=at;rotation=Vector3(0,deg_to_rad(heading_degrees),0)
	visual.position=Vector3.ZERO;visual.rotation=Vector3.ZERO
	visual.model.position=Vector3.ZERO;visual.model.rotation=Vector3.ZERO
	visual.model.scale=Vector3.ONE*visual.model_scale

func clip(clip_name:String,time:float,speed:=0.0) -> void:
	# Stateless sample: the same time always produces the same pose.
	var m=visual.motions
	m.blend_from.clear();m.previous_state=clip_name+"/idle";m.clip_elapsed=maxf(0.0,time)
	m.present({"character":index,"health":100,"state":"idle","move":"","frame":0,"y":0.0,"vy":0.0,"vx":speed,"face":1,"guarding":false,"cinematic_clip":clip_name},0.0,true)
	visual.skeleton.force_update_all_bone_transforms()

func _local(direction:Vector3) -> Vector3:
	return (visual.skeleton.global_basis.orthonormalized().inverse()*direction).normalized()

func aim(bone:String,child:String,world_direction:Vector3,weight:=1.0) -> void:
	visual.motions._aim_limb(bone,child,_local(world_direction),weight)

func twist(bone:String,world_axis:Vector3,angle:float) -> void:
	var id:int=visual.motions.bone_index(bone)
	if id<0:return
	var sk:Skeleton3D=visual.skeleton
	var pose:Basis=sk.get_bone_global_pose(id).basis.orthonormalized()
	var desired:Basis=Basis(_local(world_axis),angle)*pose
	var parent:int=sk.get_bone_parent(id)
	var parent_basis:Basis=Basis.IDENTITY if parent<0 else sk.get_bone_global_pose(parent).basis.orthonormalized()
	sk.set_bone_pose_rotation(id,(parent_basis.inverse()*desired).get_rotation_quaternion())
	sk.force_update_all_bone_transforms()

func reach(side:String,world_target:Vector3,world_pole:Vector3) -> void:
	solver.solve_arm(side,world_target,world_pole)

func point(bone:String) -> Vector3:
	return solver.point(bone)

func forward() -> Vector3:return global_basis.z.normalized()
func right() -> Vector3:return -global_basis.x.normalized()

func ground(floor_y:float) -> void:
	# Bent-knee clips keep the hips high; drop the root until a foot touches.
	var low:=INF
	for bone in ["LeftFoot","RightFoot","LeftToeBase","RightToeBase"]:
		if visual.motions.bone_index(bone)>=0:low=minf(low,point(bone).y)
	if is_finite(low):global_position.y+=floor_y+.07-low

func seat(seat_y:float) -> void:
	global_position.y+=seat_y-point("Hips").y

func finish(floor_y:float,visible_shadow:=true) -> void:
	shadow.visible=visible and visible_shadow
	var hips:Vector3=point("Hips")
	shadow.global_position=Vector3(hips.x,floor_y+.012,hips.z)
	shadow.global_rotation=Vector3.ZERO
