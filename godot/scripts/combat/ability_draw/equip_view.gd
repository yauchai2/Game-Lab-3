extends Node3D
## Current selected fighter, real skeletal contacts, one stateless authored timeline.
const Prop=preload("res://scripts/combat/ability_draw/core_prop.gd")
const Contact=preload("res://scripts/combat/ability_draw/dealer_rig.gd")
var hero:Node3D
var module:Node3D
var solver:Node3D
var g:Node3D
var rings:Array[Node3D]=[]
var smoke:Array[Node3D]=[]
var bolts:Array[MeshInstance3D]=[]
var camera_at:=Vector3.ZERO
var target:=Vector3.ZERO
var fov:=52.0
var punch:=0.0
var time:=0.0
var contact_error:=0.0
var shot:=0
func setup(selection:int,id:String) -> void:
    if hero==null:
        hero=preload("res://scripts/combat/fighter_visual.gd").new();add_child(hero)
    if hero.model==null or hero.character_index!=selection:hero.setup(Color.WHITE,selection)
    hero.rotation=Vector3.ZERO;hero.position=Vector3.ZERO;hero.model.position=Vector3.ZERO;hero.model.rotation=Vector3.ZERO;hero.model.scale=Vector3.ONE*hero.model_scale
    var baton:Node=hero.find_child("SignalBaton",true,false)
    if baton!=null:baton.hide()
    if module!=null:module.get_parent().remove_child(module);module.queue_free()
    module=Prop.new();add_child(module);module.build(id)
    if solver==null:solver=Contact.new();add_child(solver)
    solver.model=hero.model;solver.skeleton=hero.skeleton;solver.motions=hero.motions
    solver.hand_frames.clear()
    for side in ["Left","Right"]:
        var sk:Skeleton3D=hero.skeleton
        var hand:int=solver.bone(side+"Hand")
        var origin:Vector3=sk.get_bone_global_rest(hand).origin
        var forward:Vector3=(sk.get_bone_global_rest(solver.bone(side+"HandMiddle1")).origin-origin).normalized()
        var across:Vector3=(sk.get_bone_global_rest(solver.bone(side+"HandIndex1")).origin-sk.get_bone_global_rest(solver.bone(side+"HandPinky1")).origin).normalized()
        var normal:Vector3=across.cross(forward).normalized()
        solver.hand_frames[side]=sk.get_bone_global_rest(hand).basis.orthonormalized().inverse()*solver.frame_from(forward,normal)
    if g==null:
        g=preload("res://scripts/combat/ability_draw/visuals.gd").new();add_child(g)
        for i in 3:
            var torus:=TorusMesh.new();torus.inner_radius=.20;torus.outer_radius=.225;torus.rings=20;torus.ring_segments=4
            rings.append(g.mesh(g,torus,Vector3.ZERO,module.color,false,true))
        for i in 18:
            var sphere:=SphereMesh.new();sphere.radius=.12;sphere.height=.19;sphere.radial_segments=5;sphere.rings=2
            smoke.append(g.mesh(g,sphere,Vector3.ZERO,Color("c7c0b7")))
        for i in 8:bolts.append(g.box(g,Vector3.ZERO,Vector3(.018,.12,.018),module.color,false,true))
    for r in rings:r.material_override=g.mat(module.color,true)
    for b in bolts:b.material_override=g.mat(module.color,true)
    show()
func sample(t:float,reduced:bool) -> void:
    time=t
    var m=hero.motions
    m.blend_from.clear();m.previous_state="Idle_Loop/idle";m.clip_elapsed=0
    m.present({"character":hero.character_index,"health":100,"state":"idle","move":"","frame":0,"y":0.0,"vy":0.0,"vx":0.0,"face":1,"guarding":false,"showcase":true},0,true)
    var up:=Vector3.UP
    var foot_before:Vector3=solver.point("RightFoot")
    var resting_wrist:Vector3=solver.point("RightHand")
    var stomp:=sin(smoothstep(2.90,3.32,t)*PI)*.08
    m._aim_limb("RightUpLeg","RightLeg",-m.model_up+m.model_forward*stomp*3,1)
    m._aim_limb("RightLeg","RightFoot",-m.model_up-m.model_forward*stomp*2,1)
    hero.skeleton.force_update_all_bone_transforms()
    module.global_transform=Prop.socket_frame(hero)
    var socket:Transform3D=module.global_transform
    var grip:=smoothstep(.16,.48,t)
    var seat:=smoothstep(1.32,2.40,t)
    var release:=smoothstep(2.62,2.94,t)
    var initial:Vector3=socket.origin+Vector3(-.04,.12,.20)
    var core_position:Vector3=initial.lerp(socket.origin+socket.basis.z*.10,seat)
    core_position+=up*sin(seat*PI)*.06
    if t<.28:core_position+=Vector3(.08,.06,.04)*(1-smoothstep(0,.28,t))
    var core_rotation:=socket.basis*Basis(Vector3.RIGHT,seat*PI/2)
    module.capsule.global_transform=Transform3D(core_rotation.scaled(Vector3.ONE*.40),core_position)
    module.pose_clips(smoothstep(2.32,2.48,t),t>=2.42)
    var wrist_target:Vector3=core_position+socket.basis.x*.075-socket.basis.z*.025
    wrist_target=wrist_target.lerp(resting_wrist,release)
    solver.solve_arm("Right",wrist_target,socket.origin+Vector3(-.6,.15,.1))
    var fingers:Vector3=core_rotation.y
    solver.orient_hand("Right",fingers,-socket.basis.z,grip*(1-release))
    contact_error=solver.point("RightHand").distance_to(wrist_target)
    m._aim_limb("LeftArm","LeftForeArm",-m.model_up+m.model_forward*.08,1)
    m._aim_limb("LeftForeArm","LeftHand",-m.model_up+m.model_forward*.12,1)
    var foot:Vector3=solver.point("RightFoot")
    var energy:=clampf((t-2.72)/.58,0,1)
    for i in rings.size():
        var r:Node3D=rings[i];r.visible=t>2.74 and t<3.64 and not reduced
        r.global_position=foot+up*(.10+i*.14+(1-energy)*.5);r.scale=Vector3.ONE*(.65+energy*.4)
    for i in bolts.size():
        var p:Vector3=socket.origin.lerp(foot,clampf(energy+(float(i)/8-.5)*.25,0,1))
        p+=Vector3(sin(i*3.1+t*37)*.04,0,.12)
        bolts[i].global_position=p;bolts[i].visible=t>2.74 and t<3.48 and (not reduced or i<2)
    var life:=clampf((t-3.28)/.62,0,1)
    for i in smoke.size():
        var puff:Node3D=smoke[i];var a:=i*2.399
        puff.visible=life>0 and life<1 and (not reduced or i<4)
        puff.global_position=Vector3(foot.x,global_position.y+.03,foot.z)+Vector3(cos(a)*life*.8,sin(life*PI)*.16,sin(a)*life*.4)
        puff.scale=Vector3.ONE*(.4+life*1.4)*(1-life)
    punch=maxf(maxf(0,1-absf(t-.42)/.075),maxf(0,1-absf(t-2.44)/.10))
    punch=maxf(punch,maxf(0,1-absf(t-3.30)/.12))
    shot=0 if t<1.32 else (1 if t<2.72 else (2 if t<3.76 else 3))
    target=core_position
    camera_at=target+Vector3(-.03,.005,.56);fov=48
    if shot==1:target=socket.origin+Vector3(0,0,.13);camera_at=target+Vector3(.32,.10,.84);fov=52
    elif shot==2:target=foot.lerp(foot_before,.1)+Vector3(0,.02,.04);camera_at=target+Vector3(-.62,.75,1.05);fov=66
    elif shot==3:target=socket.origin.lerp(foot,.55);camera_at=target+Vector3(.22,.12,1.50);fov=50
    if reduced:punch=0
func clear() -> void:hide()
