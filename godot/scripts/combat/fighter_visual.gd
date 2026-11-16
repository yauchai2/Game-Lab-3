extends Node3D
const CoreProp=preload("res://scripts/combat/ability_draw/core_prop.gd")
const Roster = preload("res://scripts/combat/fighter_roster.gd")
const Toon = preload("res://shaders/fighter_toon.gdshader")
const Outline = preload("res://shaders/fighter_outline.gdshader")
static var retired_materials:Array[ShaderMaterial]=[]
var baton_tip:Node3D
var core_module:Node3D
var model: Node3D
var skeleton: Skeleton3D
var materials: Array[ShaderMaterial] = []
var team := Color("66e5db")
var neon_enabled:=false
var character_index := 0
var deadshift_id:=""
var model_scale := 2.1
var oversized_bones: Array[int]=[]
var fx_flash_age:=1.0
var fx_bones:Dictionary={}
var elapsed := 0.0
var reaction_age:=1.0
var reaction_duration:=0.0
var reaction_direction:=1.0
var reaction_pitch:=0.0
var reaction_airborne:=false
var death_ground_offset:=0.0
var death_ground_cached:=false
var death_surfaces:Array=[]
const PairedMotion=preload("res://scripts/combat/paired_throw_motion.gd")
var paired_motion=PairedMotion.new()
var paired_floor_cache:Dictionary={}
var foot_contact:=preload("res://scripts/combat/last_service/foot_contact.gd").new()
var motions := preload("res://scripts/combat/combat_motions.gd").new()

func setup(color: Color, selection := 0, model_path_override:="", height_override:=0.0) -> void:
    var snap:=get_node_or_null("DeadshiftSnap")
    if snap!=null:remove_child(snap);snap.queue_free()
    deadshift_id=""
    if core_module!=null:core_module.queue_free();core_module=null
    foot_contact=preload("res://scripts/combat/last_service/foot_contact.gd").new()
    team = color
    character_index=clampi(selection,0,Roster.BLACK_SUIT_INDEX)
    var entry:Dictionary=Roster.entry(character_index)
    if is_instance_valid(model):
        # Compatibility may still process dependencies for an outgoing instance
        # on this frame, especially before its first draw. Keep its materials
        # alive until that draw completes rather than leave stale renderer RIDs.
        if DisplayServer.get_name()!="headless" and not materials.is_empty():
            retired_materials.append_array(materials)
            if not RenderingServer.frame_post_draw.is_connected(_release_retired_materials):
                RenderingServer.frame_post_draw.connect(_release_retired_materials,CONNECT_ONE_SHOT)
        remove_child(model)
        model.queue_free()
    skeleton=null
    baton_tip=null
    fx_bones.clear()
    fx_flash_age=1.0
    clear_impact_reaction()
    materials.clear()
    oversized_bones.clear()
    paired_motion=PairedMotion.new()
    paired_floor_cache.clear()
    motions=preload("res://scripts/combat/combat_motions.gd").new()
    elapsed=0.0
    death_ground_cached=false
    death_ground_offset=0.0
    death_surfaces.clear()
    model_scale=height_override if height_override>0.0 else entry.scale
    model = (load(entry.path if model_path_override.is_empty() else model_path_override) as PackedScene).instantiate()
    model.scale = Vector3.ONE * model_scale
    add_child(model)
    for mesh in model.find_children("*", "MeshInstance3D", true, false):
        for surface in mesh.mesh.get_surface_count():
            var original: Material = mesh.get_active_material(surface)
            var mat := ShaderMaterial.new()
            mat.shader = preload("res://shaders/neon/neon_actor.gdshader") if neon_enabled else Toon
            mat.set_shader_parameter("tint", Color.WHITE.lerp(team, 0.50))
            if character_index==Roster.BLACK_SUIT_INDEX:mat.set_shader_parameter("tint",original.albedo_color if original is BaseMaterial3D else Color.WHITE)
            if original is BaseMaterial3D and original.albedo_texture:
                mat.set_shader_parameter("use_texture", true)
                mat.set_shader_parameter("base_texture", original.albedo_texture)
            if neon_enabled:
                mat.set_shader_parameter("tint",original.albedo_color if character_index==Roster.BLACK_SUIT_INDEX and original is BaseMaterial3D else Color.WHITE)
                mat.set_shader_parameter("neon_accent",preload("res://scripts/combat/neon/neon_style_profile.tres").accent(character_index))
            var outline := ShaderMaterial.new()
            outline.shader = Outline
            outline.set_shader_parameter("repaired_suit_neck",character_index==Roster.BLACK_SUIT_INDEX and model.find_child("NeckBridge",true,false)!=null)
            if character_index!=Roster.BLACK_SUIT_INDEX or not str(mesh.name).begins_with("Repair") and str(mesh.name) not in ["NeckBridge","CleanShirtInsert","TieKnot","TieBlade"]:
                mat.next_pass = outline
            mesh.set_surface_override_material(surface, mat)
            materials.append(mat)
    var list := model.find_children("*", "Skeleton3D", true, false)
    if not list.is_empty():
        skeleton = list[0]
        motions.setup(skeleton,model)
        for mesh in model.find_children("*","MeshInstance3D",true,false):
            if mesh.skin==null:continue
            var binds:Array=[]
            for index in mesh.skin.get_bind_count():
                var bone:int=mesh.skin.get_bind_bone(index)
                if bone<0:bone=skeleton.find_bone(mesh.skin.get_bind_name(index))
                binds.append({"bone":bone,"pose":mesh.skin.get_bind_pose(index)})
            for surface in mesh.mesh.get_surface_count():
                var arrays:Array=mesh.mesh.surface_get_arrays(surface)
                if arrays[Mesh.ARRAY_BONES]==null or arrays[Mesh.ARRAY_WEIGHTS]==null:continue
                death_surfaces.append({"vertices":arrays[Mesh.ARRAY_VERTEX],"bones":arrays[Mesh.ARRAY_BONES],"weights":arrays[Mesh.ARRAY_WEIGHTS],"binds":binds})
        if character_index==3:_add_signal_baton()
        if character_index==Roster.BLACK_SUIT_INDEX and model_path_override.is_empty():_add_pistol()

static func _release_retired_materials() -> void:
    retired_materials.clear()

func clear_impact_reaction() -> void:
    reaction_duration=0.0

func impact_reaction(kind:String,move:String,direction:float,airborne:bool,strength:float) -> void:
    reaction_age=0.0
    reaction_direction=direction
    reaction_airborne=airborne
    var weight:=clampf(strength,0.2,1.0)
    reaction_duration=lerpf(.12,.22,weight) if airborne else .11
    reaction_pitch=lerpf(.24,.55,weight) if airborne else lerpf(.09,.19,weight)
    if move in ["meteor","air_counter"]:reaction_pitch=-.66
    elif move=="launcher":reaction_pitch=.57
    elif move=="air_kick":reaction_pitch=maxf(.42,reaction_pitch)
    if kind in ["air_land","ground_bounce"]:
        reaction_duration=.13
        reaction_pitch=-.33
    elif kind=="block":
        reaction_duration=.085
        reaction_pitch=.095
    elif kind=="arena_bounce":
        reaction_duration=.16
        reaction_pitch=-.46

func _pose_impact_limbs(f:Dictionary,weight:float) -> void:
    var up:Vector3=motions.model_up
    var forward:Vector3=motions.model_forward
    var right:Vector3=up.cross(forward).normalized()
    var away:Vector3=forward*reaction_direction*float(f.face)
    var folding:=reaction_pitch<0.0
    for side in ["Left","Right"]:
        var spread:Vector3=right*(-1.0 if side=="Left" else 1.0)
        var accent:float=weight*(1.0 if side=="Left" else .72)
        motions._aim_limb(side+"Arm",side+"ForeArm",spread*.62-up*.30-away*(.42 if folding else .25),accent*.7)
        motions._aim_limb(side+"ForeArm",side+"Hand",spread*.30+up*.38-away*.32,accent*.6)
        motions._aim_limb(side+"UpLeg",side+"Leg",-up*.65+away*(.22 if folding else -.38)+spread*.16,accent*.8)
        motions._aim_limb(side+"Leg",side+"Foot",-up*.6+away*(.64 if folding else .44),accent*.75)

func present(f: Dictionary, delta: float, stopped: bool, reduced: bool, opponent_x := INF) -> void:
    # Retimed existing whole-body clips provide one pose owner for the new tactical casts.
    # The copied presentation state never changes simulation move ids or hit clocks.
    if f.state=="attack" and f.move in ["tactic_a","tactic_b"]:
        f=f.duplicate(true)
        var timing:Dictionary=f.move_data
        f.move="heavy" if f.character==1 else ("cross" if f.character==2 else "special")
        if f.character==0:f.move="cross"
        var tactical_id:int=int(f.tactical.get("cast_skill",-1))
        if tactical_id>=2:
            f.move=[["meteor","heavy","special","overdrive"],["heavy","jab","overdrive","special"],["cross","special","special","overdrive"],["special","cross","special","overdrive"]][int(f.character)][tactical_id-2]
        var base:Dictionary=preload("res://scripts/combat/fight_simulation.gd").MOVES[f.move]
        var authored:Dictionary=preload("res://scripts/combat/last_service/profiles.gd").move(base,f.character,f.move,f)
        f.frame=roundi(float(f.frame)*float(authored.startup)/float(timing.startup)) if f.frame<=timing.startup else int(authored.startup)+int(f.frame)-int(timing.startup)
        f.move_data=authored
    if deadshift_id!="":
        f=f.duplicate()
        f["deadshift_id"]=deadshift_id
    if PairedMotion.owns(f) and skeleton!=null:
        if not paired_motion.active_last:foot_contact.clear()
        for bone in oversized_bones:skeleton.set_bone_pose_scale(bone,Vector3.ONE)
        oversized_bones.clear()
        position=Vector3(f.x,0,3.0)
        rotation.y=PI*.5 if f.face>0 else -PI*.5
        model.rotation=Vector3.ZERO;model.scale=Vector3.ONE*model_scale
        model.position=basis.inverse()*Vector3(0,0,float(f.paired_throw.depth))
        paired_motion.present(self,f,delta,stopped)
        var key:String=str(f.paired_throw.serial)+"/"+str(f.paired_throw.role)+"/"+str(f.paired_throw.age)
        if not paired_floor_cache.has(key):
            paired_floor_cache.clear()
            paired_floor_cache[key]=(.01-lowest_skin_y()) if float(f.paired_throw.recover)>0 and f.health>0 else maxf(0.0,.01-lowest_skin_y())
        model.position.y=float(paired_floor_cache[key])
        for mat in materials:mat.set_shader_parameter("flash",1.0 if f.flash>0 and not reduced else 0.0)
        _present_pistol(f)
        _present_core(f)
        return
    paired_motion.active_last=false
    var snap:=get_node_or_null("DeadshiftSnap")
    if snap!=null:snap.present(f,delta,stopped)
    for bone in oversized_bones:skeleton.set_bone_pose_scale(bone,Vector3.ONE)
    oversized_bones.clear()
    elapsed += delta
    position = Vector3(f.x, f.y, 3.0)
    # Imported +Z forward maps to gameplay +X at +90 degrees.
    rotation.y = PI * 0.5 if f.face > 0 else -PI * 0.5
    var profile_owned:bool=preload("res://scripts/combat/last_service/street_motion.gd").owns(f) or preload("res://scripts/combat/mixamo_profiles.gd").owns(f) or deadshift_id!=""
    var shake := 0.0 if reduced or not stopped or profile_owned else 0.025
    var lunge := 0.0
    if f.state=="attack" and not profile_owned:
        var move: Dictionary = f.get("move_data",preload("res://scripts/combat/fight_simulation.gd").MOVES[f.move])
        var amount := clampf(float(f.frame)/move.startup,0,1)
        if f.frame>move.startup+move.active:
            amount = 1.0-clampf(float(f.frame-move.startup-move.active)/move.recovery,0,1)
        lunge = 0.0 if f.move=="gun" else amount * (0.60 if f.move in ["heavy","finisher"] else 0.45)
        if is_finite(opponent_x): lunge = minf(lunge,maxf(0.0,absf(opponent_x-f.x)-0.8))
    model.position = Vector3(sin(elapsed * 137.0) * shake,0,lunge)
    var exchange_choice: String=f.get("exchange_choice","")
    model.rotation.x={"press":-.12,"turn":.10,"slip":.22}.get(exchange_choice,0.0)
    if exchange_choice!="":
        model.position.z += {"press":.12,"turn":-.06,"slip":-.18}.get(exchange_choice,0.0)
    # Authored visual deformation, kept separate from gameplay transforms.
    var stretch:=Vector3.ONE
    if not reduced and not profile_owned:
        if stopped:stretch=Vector3(1.06,.94,1.06)
        elif f.state=="dash":stretch=Vector3(.91,.92,1.20)
        elif f.state=="attack" and f.move in ["heavy","special","overdrive","finisher"]:
            var move: Dictionary=f.get("move_data",preload("res://scripts/combat/fight_simulation.gd").MOVES[f.move])
            var anticip: float=clampf(float(f.frame)/move.startup,0,1)
            stretch=Vector3(1.0+anticip*.05,1.0-anticip*.07,1.0+anticip*.11)
    var rally_phase: String=f.get("rally_phase","")
    if rally_phase!="":
        var amount: float=clampf(f.get("rally_amount",0.0),0,1)
        var attacking: bool=f.get("rally_owner",false)
        model.rotation.x=(-.12-amount*.12 if attacking else .12) if rally_phase=="compress" else 0.0
        if rally_phase=="compress" and not reduced:stretch=Vector3(1.05,.93,1.08)
    if f.get("air_enabled",false) and not profile_owned:stretch*=motions.air_poses.stretch(f,reduced)
    model.rotation.y=0.0
    if f.get("air_enabled",false) and not profile_owned and not reduced and f.state=="idle" and f.air.phase=="rise" and f.air.air_ticks<=8:
        model.rotation.y=TAU*float(f.air.air_ticks)/8.0
    if f.get("ko_theatre",-1.0)>=0:
        var pose_time:float=f.ko_theatre
        model.rotation.x+=(-.35 if f.health<=0 else .12)*sin(pose_time*PI/.64)
        if f.health<=0:model.rotation.z=sin(pose_time*PI/.64)*.55
        stretch*=Vector3(1.18,.92,1.18)
    else:model.rotation.z=0.0
    if f.get("ricochet",{}).get("ticks",0)>0 and f.state=="stun" and not reduced:
        var spin:float=f.ricochet.spin
        model.rotation.x=spin
        # Rotate about the torso instead of driving the head through the floor.
        model.position.y+=1.1*(1-cos(spin));model.position.z-=1.1*sin(spin)
        stretch*=Vector3(1.07,.93,1.07)
    if f.has("ko_spin") and not reduced:
        # KO flight tumbles about the torso so the body arcs instead of pivoting at the feet.
        var tumble:float=f.ko_spin
        model.rotation.x=tumble
        model.position.y+=1.1*(1-cos(tumble));model.position.z-=1.1*sin(tumble)
        var squash:float=f.get("ko_squash",0.0)
        stretch*=Vector3(1.0+squash*.12,1.0-squash*.16,1.0+squash*.12)
    var reaction_weight:=0.0
    var ricochet_live:bool=f.get("ricochet",{}).get("ticks",0)>0
    var can_react:bool=f.health>0 and not f.has("cinematic_clip") and not f.get("showcase",false) and not f.has("ko_spin") and f.get("ko_theatre",-1.0)<0 and rally_phase=="" and exchange_choice=="" and f.get("air_counter_phase","")!="hold"
    if reaction_duration>0.0 and can_react and f.state in ["stun","blockstun","landing","idle"]:
        reaction_weight=1.0-smoothstep(0.015,reaction_duration,reaction_age)
        if not stopped:reaction_age+=delta
        if reaction_age>=reaction_duration:clear_impact_reaction()
        var pitch:float=reaction_pitch*reaction_direction*float(f.face)*reaction_weight*(.58 if reduced else 1.0)
        if not ricochet_live or reduced:
            model.rotation.x+=pitch
            if reaction_airborne:
                var pivot:=.95
                model.position.y+=pivot*(1.0-cos(pitch))
                model.position.z-=pivot*sin(pitch)
    elif reaction_duration>0.0:
        clear_impact_reaction()
    model.scale=Vector3.ONE*model_scale*stretch
    for mat in materials:
        mat.set_shader_parameter("flash", (1.0 if fx_flash_age<.045 else .16) if f.flash > 0 and not reduced else 0.0)
    if skeleton:
        motions.present(f,delta,stopped)
        if reaction_weight>0.0 and reaction_airborne and f.y>.01:
            _pose_impact_limbs(f,reaction_weight*(.65 if reduced else 1.0))
        _present_pistol(f)
        if neon_enabled and f.health>0:preload("res://scripts/combat/neon/neon_signature_motion.gd").apply(motions,f)
        if not profile_owned and f.health>0 and f.get("rush_visual",false) and f.state=="attack" and f.move!="gun":
            var move: Dictionary=f.get("move_data",preload("res://scripts/combat/fight_simulation.gd").MOVES[f.move])
            if f.frame>=move.startup-1 and f.frame<move.startup+move.active:
                var limbs:Array=["LeftHand","RightHand"] if f.move in ["meteor","overdrive"] else ["RightFoot" if f.move in ["air_kick","air_counter"] else ("LeftHand" if f.move in ["jab","air_jab"] else "RightHand")]
                if character_index==0:
                    limbs=["LeftFoot" if f.move in ["jab","special"] else "RightFoot"]
                for limb in limbs:
                    var index:=motions.bone_index(limb)
                    if index>=0:
                        skeleton.set_bone_pose_scale(index,Vector3.ONE*2.1)
                        oversized_bones.append(index)
                model.scale*=Vector3(1.05,.94,1.20)
        if f.health>0:
            death_ground_cached=false
            if character_index<4:foot_contact.apply(self,f,stopped)
            if (profile_owned or reaction_weight>0.0) and f.y<=.01 and not ricochet_live:
                # The oversized stylized shoes extend below ankle IK's contact point.
                # Correct the rendered skin floor, retaining all simulation transforms.
                model.position.y+=maxf(0.0,.01-lowest_skin_y())
        elif f.y<=.01 and f.get("ko_theatre",-1.0)<0:
            # A grounded corpse is no longer a spinning/airborne hit pose.
            model.rotation=Vector3.ZERO
            model.scale=Vector3.ONE*model_scale
            model.position=Vector3.ZERO
            _ground_death_pose()
    _present_core(f)
func _present_core(f:Dictionary) -> void:
    var id:String=f.get("draw_core","")
    if id.is_empty():
        if core_module!=null:core_module.hide()
        return
    if core_module==null or core_module.core_id!=id:
        if core_module!=null:core_module.queue_free()
        core_module=CoreProp.new();add_child(core_module);core_module.build(id)
    skeleton.force_update_all_bone_transforms()
    core_module.show();core_module.global_transform=CoreProp.socket_frame(self)


func _ground_death_pose() -> void:
    if not death_ground_cached:
        var lowest:=INF
        # CPU skinning avoids render-server registration/readback, including on
        # the first frame and in headless tests. Source arrays are cached at setup.
        for surface in death_surfaces:
            var transforms:Array[Transform3D]=[]
            for bind in surface.binds:
                transforms.append(skeleton.global_transform*skeleton.get_bone_global_pose(bind.bone)*bind.pose)
            var slots:int=floori(float(surface.bones.size())/surface.vertices.size())
            for vertex in surface.vertices.size():
                var at:=Vector3.ZERO
                for slot in slots:
                    var offset:int=vertex*slots+slot
                    var weight:float=surface.weights[offset]
                    if weight>0:at+=(transforms[surface.bones[offset]]*surface.vertices[vertex])*weight
                lowest=minf(lowest,at.y)
        death_ground_offset=global_position.y+.015-lowest if is_finite(lowest) else 0.0
        # Only the fall changes the skin. Settled corpses reuse the offset.
        death_ground_cached=motions.clip_elapsed>=motions.library.clips.Death01.duration
    model.position.y=death_ground_offset

func capture_echo() -> Array:
    var segments: Array=[]
    if not is_instance_valid(skeleton):return segments
    var pairs := [["Hips","Spine2",.19],["Spine2","Head",.15],
        ["LeftArm","LeftForeArm",.075],["LeftForeArm","LeftHand",.06],
        ["RightArm","RightForeArm",.075],["RightForeArm","RightHand",.06],
        ["LeftUpLeg","LeftLeg",.11],["LeftLeg","LeftFoot",.09],
        ["RightUpLeg","RightLeg",.11],["RightLeg","RightFoot",.09]]
    for pair in pairs:
        var indices:=[]
        for label in [pair[0],pair[1]]:
            var found:=-1
            for i in skeleton.get_bone_count():
                if skeleton.get_bone_name(i).trim_prefix("mixamorig_")==label or skeleton.get_bone_name(i).get_slice(":",1)==label:
                    found=i
                    break
            indices.append(found)
        if indices[0]<0 or indices[1]<0:continue
        var a: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(indices[0]).origin
        var b: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(indices[1]).origin
        segments.append({"a":a,"b":b,"width":pair[2]*model_scale/2.1})
    return segments

func set_neon_silhouette(enabled:bool) -> void:
    if not neon_enabled:return
    for mat in materials:
        mat.set_shader_parameter("neon_silhouette",1.0 if enabled else 0.0)
        if mat.next_pass:mat.next_pass.set_shader_parameter("silhouette_preview",enabled)

func _add_signal_baton() -> void:
    var hand:int=motions.bone_index("RightHand")
    if hand<0:return
    var grip_offset:=Vector3.ZERO
    var knuckle:int=motions.bone_index("RightHandMiddle1")
    if knuckle>=0:
        grip_offset=(skeleton.get_bone_global_rest(hand).affine_inverse()*skeleton.get_bone_global_rest(knuckle).origin)*.55
    var mount:=BoneAttachment3D.new();mount.name="SignalBaton";mount.bone_name=skeleton.get_bone_name(hand);skeleton.add_child(mount)
    baton_tip=Node3D.new();baton_tip.name="SignalBatonTip";baton_tip.position=grip_offset+Vector3(0,.145,0);mount.add_child(baton_tip)
    for spec in [[Vector3.ZERO,Vector3(.035,.25,.035),Color("10151a")],[Vector3(0,.125,0),Vector3(.05,.04,.05),Color("b8ff00")]]:
        var box:=BoxMesh.new();box.size=spec[1]
        var mat:=ShaderMaterial.new();mat.shader=preload("res://shaders/neon/neon_actor.gdshader") if neon_enabled else Toon
        mat.set_shader_parameter("tint",spec[2])
        if neon_enabled:mat.set_shader_parameter("neon_accent",Color("b8ff00"))
        var border:=ShaderMaterial.new();border.shader=Outline;mat.next_pass=border
        box.material=mat
        var node:=MeshInstance3D.new();node.name="SignalBatonMesh";node.mesh=box;node.position=spec[0]+grip_offset;mount.add_child(node)
        materials.append(mat)

## Chunky low-poly pistol (flat unshaded blocks + ink outline pass). Only shown while the gun move is playing.
func _add_pistol() -> void:
    var hand:int=motions.bone_index("RightHand")
    if hand<0:return
    var mount:=BoneAttachment3D.new();mount.name="Pistol";mount.bone_name=skeleton.get_bone_name(hand);skeleton.add_child(mount)
    mount.visible=false
    # Slide/barrel run along the hand's long axis (+Y), grip hangs off -Z, muzzle tip is the hot accent.
    for spec in [[Vector3(0,.14,.02),Vector3(.06,.22,.07),Color("15191f")],[Vector3(0,.27,.02),Vector3(.035,.05,.035),Color("ff3d6e")],[Vector3(0,.07,-.05),Vector3(.055,.09,.05),Color("2a2f3a")]]:
        var box:=BoxMesh.new();box.size=spec[1]
        var mat:=ShaderMaterial.new();mat.shader=preload("res://shaders/neon/neon_actor.gdshader") if neon_enabled else Toon
        mat.set_shader_parameter("tint",spec[2])
        if neon_enabled:mat.set_shader_parameter("neon_accent",Color("ff3d6e"))
        var border:=ShaderMaterial.new();border.shader=Outline;mat.next_pass=border
        box.material=mat
        var node:=MeshInstance3D.new();node.name="PistolMesh";node.mesh=box;node.position=spec[0];mount.add_child(node)
        materials.append(mat)

func _present_pistol(f:Dictionary) -> void:
    var mount:=skeleton.get_node_or_null("Pistol")
    if mount!=null:mount.visible=f.health>0 and f.state=="attack" and f.move=="gun"

## Socket positions belong to presentation; never used as gameplay hitboxes.
func fx_socket(label:String) -> Vector3:
    if label=="BatonTip" and is_instance_valid(baton_tip):
        var hand:int=motions.bone_index("RightHand")
        if hand>=0:return skeleton.global_transform*skeleton.get_bone_global_pose(hand)*baton_tip.position
    if is_instance_valid(skeleton):
        if not fx_bones.has(label):fx_bones[label]=motions.bone_index(label)
        var index:int=fx_bones[label]
        if index>=0:
            return skeleton.global_transform*skeleton.get_bone_global_pose(index).origin
    return global_position+Vector3(0,.10 if label.ends_with("Foot") else model_scale*.60,0)

func fx_advance_flash(delta:float,reduced:bool) -> void:
    fx_flash_age+=maxf(0,delta)
    if reduced:fx_flash_age=1.0
    if fx_flash_age>=.045:
        for mat in materials:
            var current:float=mat.get_shader_parameter("flash")
            if current>.16:mat.set_shader_parameter("flash",0.0 if reduced else .16)

func lowest_skin_y() -> float:
    skeleton.force_update_all_bone_transforms()
    var lowest:=INF
    for surface in death_surfaces:
        var transforms:Array[Transform3D]=[]
        for bind in surface.binds:
            transforms.append(skeleton.global_transform*skeleton.get_bone_global_pose(bind.bone)*bind.pose)
        var slots:int=floori(float(surface.bones.size())/surface.vertices.size())
        for vertex in surface.vertices.size():
            var at:=Vector3.ZERO
            for slot in slots:
                var offset:int=vertex*slots+slot
                var weight:float=surface.weights[offset]
                if weight>0:at+=(transforms[surface.bones[offset]]*surface.vertices[vertex])*weight
            lowest=minf(lowest,at.y)
    return lowest if is_finite(lowest) else 0.0
