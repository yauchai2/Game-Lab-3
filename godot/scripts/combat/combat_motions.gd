extends RefCounted
## Rest-relative retargeting of the CC0 Quaternius library onto the supplied rig.
static var library: Dictionary = {}
var skeleton: Skeleton3D
var source_rest: Array[Quaternion] = []
var source_global_rest: Array[Quaternion] = []
var target_global_rest: Array[Quaternion] = []
var target_local_rest: Array[Quaternion] = []
var mapping: Dictionary = {}
var alignment := Quaternion.IDENTITY
var source_hips := -1
var target_hips := -1
var height_scale := 1.0
var contact_phases := {"Punch_Jab":0.30,"Punch_Cross":0.30,"Spell_Simple_Shoot":0.42}
var clip_name := ""
var clip_elapsed := 0.0
var blend_from: Array[Quaternion] = []
var previous_state := ""
var previous_y := 0.0
var land_time := 1.0
var air_time := 0.0
var air_poses:=preload("res://scripts/combat/aerial_poses.gd").new()
var air_pose_name:=""
var model_forward := Vector3.BACK
var model_up := Vector3.UP

func setup(target: Skeleton3D, model: Node3D) -> void:
    skeleton = target
    model_forward = (skeleton.global_basis.inverse() * model.global_basis.z).normalized()
    model_up = (skeleton.global_basis.inverse() * model.global_basis.y).normalized()
    if library.is_empty():
        library = JSON.parse_string(FileAccess.get_file_as_string("res://assets/animations/quaternius_combat.json"))
    for node in library.nodes:
        source_rest.append(_quat(node.rotation))
    var cache: Dictionary = {}
    for i in source_rest.size():
        source_global_rest.append(_global_rotation(i,source_rest,cache))
    var names := {"Hips":"DEF-hips","Spine":"DEF-spine.001","Spine1":"DEF-spine.002","Spine2":"DEF-spine.003","Neck":"DEF-neck","Head":"DEF-head"}
    for side in ["Left","Right"]:
        var suffix := ".L" if side=="Left" else ".R"
        for pair in [["Shoulder","shoulder"],["Arm","upper_arm"],["ForeArm","forearm"],["Hand","hand"],["UpLeg","thigh"],["Leg","shin"],["Foot","foot"],["ToeBase","toe"]]:
            names[side+pair[0]] = "DEF-"+pair[1]+suffix
        for finger in [["Thumb","thumb"],["Index","f_index"],["Middle","f_middle"],["Ring","f_ring"],["Pinky","f_pinky"]]:
            for digit in range(1,4):
                names[side+"Hand"+finger[0]+str(digit)] = "DEF-"+finger[1]+".0"+str(digit)+suffix
    for bone in skeleton.get_bone_count():
        target_global_rest.append(skeleton.get_bone_global_rest(bone).basis.get_rotation_quaternion())
        target_local_rest.append(skeleton.get_bone_rest(bone).basis.get_rotation_quaternion())
        var short_name := skeleton.get_bone_name(bone).trim_prefix("mixamorig_")
        if names.has(short_name):
            var index := _source_index(names[short_name])
            if index >= 0: mapping[bone] = index
    source_hips = _source_index("DEF-hips")
    target_hips = skeleton.find_bone("mixamorig_Hips")
    var source_transforms: Dictionary = {}
    var source_right := _source_transform(_source_index("DEF-upper_arm.R"),source_transforms).origin
    var source_left := _source_transform(_source_index("DEF-upper_arm.L"),source_transforms).origin
    var source_head := _source_transform(_source_index("DEF-head"),source_transforms).origin
    var source_hip := _source_transform(source_hips,source_transforms).origin
    var target_right := skeleton.get_bone_global_rest(skeleton.find_bone("mixamorig_RightArm")).origin
    var target_left := skeleton.get_bone_global_rest(skeleton.find_bone("mixamorig_LeftArm")).origin
    var target_head := skeleton.get_bone_global_rest(skeleton.find_bone("mixamorig_Head")).origin
    var target_hip := skeleton.get_bone_global_rest(target_hips).origin
    alignment = (_frame(target_right-target_left,target_head-target_hip) * _frame(source_right-source_left,source_head-source_hip).inverse()).get_rotation_quaternion()
    height_scale = (target_head-target_hip).length() / maxf((source_head-source_hip).length(),0.01)
    # The supplied rig has lowered arms; calibrate each limb against the source
    # bind directions so a boxing guard does not inherit that lowered-arm offset.
    for bone in mapping:
        for child in skeleton.get_bone_children(bone):
            if not mapping.has(child): continue
            var source_direction := _source_transform(mapping[child],source_transforms).origin - _source_transform(mapping[bone],source_transforms).origin
            var target_direction := skeleton.get_bone_global_rest(child).origin - skeleton.get_bone_global_rest(bone).origin
            if source_direction.length()>0.001 and target_direction.length()>0.001:
                var correction := Quaternion(target_direction.normalized(),(alignment*source_direction).normalized())
                target_global_rest[bone] = correction * target_global_rest[bone]
            break


func present(f: Dictionary, delta: float, stopped: bool) -> void:
    if not stopped:
        air_time = air_time + delta if f.y > 0.01 else 0.0
        land_time += delta
        if previous_y > 0.05 and f.y <= 0.01: land_time = 0.0
    previous_y = f.y
    var selected := "Punch_Enter"
    var loop := false
    if f.health <= 0:
        selected = "Death01"
    elif f.state == "attack":
        selected = "Punch_Jab" if f.move in ["jab","air_jab"] else "Punch_Cross"
        if f.move in ["special","overdrive"]: selected = "Spell_Simple_Shoot"
    elif f.state == "stun":
        selected = "Hit_Head" if f.vy > 2.0 else "Hit_Chest"
    elif f.state == "dash":
        selected = "Roll"
    elif f.y > 0.05:
        selected = "Jump_Start" if air_time < 0.12 and f.vy>0 else "Jump_Loop"
        loop = selected=="Jump_Loop"
    elif land_time < 0.22:
        selected = "Jump_Land"
    elif absf(f.vx) > 0.3:
        selected = "Walk_Loop" if f.vx*f.face<0 else ("Sprint_Loop" if absf(f.vx)>5.5 else ("Jog_Fwd_Loop" if absf(f.vx)>4 else "Walk_Loop"))
        loop = true
    var character:int=f.get("character",0)
    if f.state=="idle" and absf(f.vx)<.3 and f.y<=.01:
        if character==1:selected="Dance_Loop";loop=true
        elif character==2:selected="Spell_Simple_Idle_Loop";loop=true
        elif character==3:selected="Idle_Loop";loop=true
    if f.state=="attack" and character==2 and f.move in ["cross","finisher","special"]:selected="Sword_Attack";loop=false
    var state_key := selected + "/" + str(f.state) + ("/"+str(f.move) if f.state=="attack" else "")
    if state_key != previous_state:
        blend_from.clear()
        for bone in skeleton.get_bone_count(): blend_from.append(skeleton.get_bone_pose_rotation(bone))
        clip_elapsed = 0.0
        previous_state = state_key
    elif not stopped:
        clip_elapsed += delta
    clip_name = selected
    var clip: Dictionary = library.clips[selected]
    var duration: float = clip.duration
    var sample_time: float = fmod(clip_elapsed,duration) if loop else minf(clip_elapsed,duration)
    if loop and selected in ["Walk_Loop","Jog_Fwd_Loop","Sprint_Loop"]:
        sample_time = fmod(clip_elapsed * clampf(absf(f.vx)/4.0,0.7,1.6),duration)
        if f.vx*f.face<0: sample_time = duration-sample_time
    if selected == "Punch_Enter":
        sample_time = duration # Authored boxing stance, with breathing layered below.
    elif f.state == "attack":
        var move: Dictionary = f.get("move_data",preload("res://scripts/combat/fight_simulation.gd").MOVES[f.move])
        var contact: float = contact_phases.get(selected,0.42)
        if f.frame < move.startup:
            sample_time = duration * contact * float(f.frame) / move.startup
        elif f.frame < move.startup + move.active:
            sample_time = duration * lerpf(contact,contact+0.10,float(f.frame-move.startup)/move.active)
        else:
            sample_time = duration * lerpf(contact+0.10,1.0,clampf(float(f.frame-move.startup-move.active)/move.recovery,0,1))
    elif selected == "Roll":
        sample_time = duration * clampf(float(f.frame)/14.0,0,1)
    elif selected == "Jump_Start":
        sample_time = duration * clampf(air_time/0.12,0,1)
    elif selected == "Jump_Land":
        sample_time = duration * clampf(land_time / 0.22,0,1)
    var locals: Array[Quaternion] = source_rest.duplicate()
    for index in clip.tracks:
        var track: Dictionary = clip.tracks[index]
        if track.has("rotation"):
            locals[int(index)] = _sample_quat(track.rotation,sample_time)
    var globals: Dictionary = {}
    var desired: Array[Quaternion] = []
    desired.resize(skeleton.get_bone_count())
    var blend := clampf(clip_elapsed/0.06,0,1)
    for bone in skeleton.get_bone_count():
        var parent := skeleton.get_bone_parent(bone)
        var parent_rotation := Quaternion.IDENTITY if parent<0 else desired[parent]
        var global_rotation: Quaternion
        if mapping.has(bone):
            var index: int = mapping[bone]
            var source_pose := _global_rotation(index,locals,globals)
            var rotation_delta := source_pose * source_global_rest[index].inverse()
            global_rotation = alignment * rotation_delta * alignment.inverse() * target_global_rest[bone]
        else:
            global_rotation = parent_rotation * target_local_rest[bone]
        var local_rotation := (parent_rotation.inverse() * global_rotation).normalized()
        if blend_from.size() == skeleton.get_bone_count():
            local_rotation = blend_from[bone].slerp(local_rotation,blend)
        desired[bone] = parent_rotation * local_rotation
        skeleton.set_bone_pose_rotation(bone,local_rotation)
    # Keep horizontal root motion in the combat simulation. Preserve modest hip bob.
    var hips_position := skeleton.get_bone_rest(target_hips).origin
    if clip.tracks.has(str(source_hips)) and clip.tracks[str(source_hips)].has("translation"):
        var translation: Vector3 = _sample_vector(clip.tracks[str(source_hips)].translation,sample_time)
        var source_base := _vec(library.nodes[source_hips].translation)
        var parent: int = library.nodes[source_hips].parent
        var offset := alignment * (source_global_rest[parent] * (translation-source_base)) * height_scale
        hips_position.y += clampf(offset.y,-0.15,0.12)
    skeleton.set_bone_pose_position(target_hips,hips_position)
    if f.state == "attack":
        var move: Dictionary = f.get("move_data",preload("res://scripts/combat/fight_simulation.gd").MOVES[f.move])
        var attack_weight := clampf(float(f.frame)/move.startup,0,1)
        if f.frame > move.startup+move.active:
            attack_weight = 1.0-clampf(float(f.frame-move.startup-move.active)/move.recovery,0,1)
        # The free library has punches, but no unarmed kick/uppercut. Layer these
        # authored directional adjustments onto its whole-body motion explicitly.
        if f.move in ["heavy","finisher"]:
            _aim_limb("RightUpLeg","RightLeg",model_forward+model_up*0.15,attack_weight)
            _aim_limb("RightLeg","RightFoot",model_forward-model_up*0.1,attack_weight)
        elif f.move=="grab":
            for side in ["Left","Right"]:
                _aim_limb(side+"Arm",side+"ForeArm",model_forward+model_up*.10,attack_weight)
                _aim_limb(side+"ForeArm",side+"Hand",model_forward+model_up*.18,attack_weight)
        elif f.move == "launcher":
            _aim_limb("RightArm","RightForeArm",model_up+model_forward*0.35,attack_weight)
            _aim_limb("RightForeArm","RightHand",model_up+model_forward*0.65,attack_weight)

    # Original character-specific silhouettes layered onto the retargeted library.
    if f.state=="attack":
        var move:Dictionary=f.get("move_data",preload("res://scripts/combat/fight_simulation.gd").MOVES[f.move])
        var w:float=clampf(float(f.frame)/move.startup,0,1)
        if f.frame>move.startup+move.active:w=1.0-clampf(float(f.frame-move.startup-move.active)/move.recovery,0,1)
        if character==1 and f.move in ["jab","cross","finisher","special","overdrive"]:
            var side:String="Left" if f.move in ["jab","special"] else "Right"
            _aim_limb(side+"UpLeg",side+"Leg",model_forward+model_up*.45,w*.95)
            _aim_limb(side+"Leg",side+"Foot",model_forward-model_up*.15,w*.95)
            _aim_limb("Spine","Spine1",model_up-model_forward*.55,w*.65)
        elif character==2:
            _aim_limb("Spine","Spine1",model_up+model_forward*.5,w*.7)
            _aim_limb("RightArm","RightForeArm",model_forward+model_up*.3,w*.9)
        elif character==3:
            _aim_limb("Spine","Spine1",model_up+model_forward*.75,w*.65)
            _aim_limb("LeftUpLeg","LeftLeg",-model_forward+model_up*.1,w*.75)
            _aim_limb("RightArm","RightForeArm",model_forward-model_up*.1,w*.9)
    if f.guarding and f.state in ["idle","blockstun"] and f.get("rally_phase","")!="compress":
        for side in ["Left","Right"]:
            _aim_limb(side+"Arm",side+"ForeArm",model_forward*.45+model_up*.3,.6)
            _aim_limb(side+"ForeArm",side+"Hand",model_up+model_forward*.25,.8)
    if f.get("rally_phase","")=="compress":
        var amount: float=clampf(f.get("rally_amount",0.0),0,1)
        if f.get("rally_owner",false):
            _aim_limb("RightArm","RightForeArm",model_up*.25-model_forward*.55,.45+amount*.25)
            _aim_limb("RightForeArm","RightHand",model_up+model_forward*.2,.8)
        else:
            for side in ["Left","Right"]:
                _aim_limb(side+"Arm",side+"ForeArm",model_forward*.4+model_up*.3,.65)
                _aim_limb(side+"ForeArm",side+"Hand",model_up+model_forward*.3,.75)

    air_pose_name=""
    if f.get("air_enabled",false):air_pose_name=air_poses.apply(self,f)
    if f.state=="attack" and f.move in ["overdrive","launcher"]:
        var winding:bool=f.frame<f.get("move_data",preload("res://scripts/combat/fight_simulation.gd").MOVES[f.move]).startup
        if f.move=="overdrive":
            air_pose_name="Cannon_Load" if winding else "Cannon_DoublePalm"
            _aim_limb("Spine","Spine1",model_up+model_forward*(-.65 if winding else .55),.8)
            for side in ["Left","Right"]:
                _aim_limb(side+"Arm",side+"ForeArm",-model_forward+model_up*.15 if winding else model_forward,.95)
                _aim_limb(side+"ForeArm",side+"Hand",model_up if winding else model_forward,.95)
            _aim_limb("LeftUpLeg","LeftLeg",model_forward*.8-model_up,.65)
        else:
            air_pose_name="Launcher_Coil" if winding else "Launcher_Uppercut"
            _aim_limb("RightArm","RightForeArm",-model_up+model_forward*.3 if winding else model_up+model_forward*.3,.9)
            _aim_limb("RightForeArm","RightHand",model_forward if winding else model_up,.9)

    if f.state=="attack" and f.move in ["special","overdrive"]:
        air_pose_name=["Boxer_DoublePalm","Dancer_SpinKick","Bass_Hammer","Spark_Drive"][character]
        var active:bool=f.frame>=f.get("move_data",preload("res://scripts/combat/fight_simulation.gd").MOVES[f.move]).startup
        if active and character==1:
            _aim_limb("RightUpLeg","RightLeg",model_forward+model_up*.35,1.0)
            _aim_limb("RightLeg","RightFoot",model_forward,1.0)
        elif active and character==3:
            _aim_limb("LeftArm","LeftForeArm",-model_forward,.95)
            _aim_limb("RightArm","RightForeArm",model_forward,1.0)

func _aim_limb(bone_name: String, child_name: String, direction: Vector3, weight: float) -> void:
    var bone := skeleton.find_bone("mixamorig_"+bone_name)
    var child := skeleton.find_bone("mixamorig_"+child_name)
    if bone<0 or child<0: return
    var global_pose := skeleton.get_bone_global_pose(bone)
    var current_direction := skeleton.get_bone_global_pose(child).origin-global_pose.origin
    if current_direction.length()<0.001: return
    var correction := Quaternion(current_direction.normalized(),direction.normalized())
    var rotation := global_pose.basis.get_rotation_quaternion()
    var desired := rotation.slerp(correction*rotation,weight)
    var parent := skeleton.get_bone_parent(bone)
    var parent_rotation := Quaternion.IDENTITY if parent<0 else skeleton.get_bone_global_pose(parent).basis.get_rotation_quaternion()
    skeleton.set_bone_pose_rotation(bone,(parent_rotation.inverse()*desired).normalized())

func _source_index(name: String) -> int:
    for i in library.nodes.size():
        if library.nodes[i].name==name: return i
    return -1
func _global_rotation(index: int, locals: Array[Quaternion], cache: Dictionary) -> Quaternion:
    if cache.has(index): return cache[index]
    var parent: int = library.nodes[index].parent
    var result: Quaternion = locals[index] if parent<0 else _global_rotation(parent,locals,cache)*locals[index]
    cache[index] = result
    return result
func _source_transform(index: int, cache: Dictionary) -> Transform3D:
    if cache.has(index): return cache[index]
    var node: Dictionary = library.nodes[index]
    var local := Transform3D(Basis(_quat(node.rotation)),_vec(node.translation))
    var result: Transform3D = local if node.parent<0 else _source_transform(node.parent,cache)*local
    cache[index] = result
    return result
func _frame(right: Vector3, up: Vector3) -> Basis:
    var y := up.normalized()
    var x := (right-y*right.dot(y)).normalized()
    return Basis(x,y,x.cross(y)).orthonormalized()
func _interval(track: Dictionary, time: float) -> Array:
    var times: Array = track.times
    var upper := clampi(times.bsearch(time,false),1,times.size()-1) if times.size()>1 else 0
    var lower := maxi(0,upper-1)
    var weight := clampf((time-float(times[lower])) / maxf(0.000001,float(times[upper])-float(times[lower])),0,1)
    return [lower,upper,weight]
func _sample_quat(track: Dictionary, time: float) -> Quaternion:
    var interval := _interval(track,time)
    if track.get("interpolation","LINEAR")=="STEP":return _quat(track.values[interval[1] if interval[2]>=1.0 else interval[0]])
    return _quat(track.values[interval[0]]).slerp(_quat(track.values[interval[1]]),interval[2])
func _sample_vector(track: Dictionary, time: float) -> Vector3:
    var interval := _interval(track,time)
    if track.get("interpolation","LINEAR")=="STEP":return _vec(track.values[interval[1] if interval[2]>=1.0 else interval[0]])
    return _vec(track.values[interval[0]]).lerp(_vec(track.values[interval[1]]),interval[2])
func _quat(value: Array) -> Quaternion:
    return Quaternion(value[0],value[1],value[2],value[3]).normalized()
func _vec(value: Array) -> Vector3:
    return Vector3(value[0],value[1],value[2])
