extends RefCounted
## Visual casting for the story encounter. Enemy combat roles remain independent.
const ROOT="res://assets/characters/deadshift/"
const CAST=[
    {"id":"knuckle","height":2.12}, {"id":"bulk","height":2.30},
    {"id":"skid","height":2.05}, {"id":"static","height":2.02},
    {"id":"tether","height":2.18}, {"id":"foreman","height":2.44},
]
const Snap=preload("res://scripts/combat/story/deadshift_snap.gd")

static func select(f:Dictionary,wave:int,campaign:bool) -> Dictionary:
    var role:String=f.story_role
    match role:
        "boss":return {}
        "captain","heavy":return CAST[5]
        "jammer":return CAST[3]
        "guard":return CAST[1]
        "rusher":return CAST[4] if not campaign and wave==1 and f.squad_id==3 else CAST[2]
        _:return CAST[0]

static func setup(visual:Node) -> void:
    if visual.skeleton==null:return
    match visual.deadshift_id:
        "bulk":_attach(visual,"LeftForeArm","shield",.56,Vector3(0,.035,.03))
        "static":_attach(visual,"LeftHand","signal",.25,Vector3(0,.026,.01))
        "tether":
            var snap:=Snap.new()
            snap.name="DeadshiftSnap"
            visual.add_child(snap)
            snap.setup()

static func _attach(visual:Node,bone:String,asset:String,size:float,offset:Vector3) -> void:
    var index:int=visual.motions.bone_index(bone)
    if index<0:return
    var attachment:=BoneAttachment3D.new()
    attachment.name="StoryRole"
    attachment.bone_name=visual.skeleton.get_bone_name(index)
    visual.skeleton.add_child(attachment)
    var model:Node3D=load(ROOT+asset+".glb").instantiate()
    attachment.add_child(model)
    model.scale=Vector3.ONE*size
    model.position=offset

static func motion(f:Dictionary,move:Dictionary,library:Dictionary) -> Dictionary:
    if f.get("deadshift_id","")=="" or f.health<=0 or f.has("cinematic_clip") or f.has("ko_spin") or f.get("ko_theatre",-1.0)>=0.0:return {}
    if f.get("ricochet",{}).get("ticks",0)>0 or f.get("air_counter_phase","")=="hold":return {}
    var clip:=""
    var phase:=0.0
    var speed:=1.0
    var loops:=false
    var reacting:=false
    var guard:=false
    var id:String=f.deadshift_id
    match f.state:
        "attack":
            if move.is_empty() or f.move in ["gun","grab"]:return {}
            clip="MX_Jab" if f.move in ["jab","air_jab"] else ("MX_Cross" if f.move=="cross" else "MX_BodyPunch")
            if f.move in ["launcher","air_finisher"]:clip="MX_Uppercut"
            elif id=="skid" and f.move in ["heavy","finisher","air_kick"]:clip="MX_Roundhouse"
            elif id=="knuckle" and f.move in ["heavy","finisher"]:clip="MX_Elbow"
            if not library.street_markers.has(clip):return {}
            phase=preload("res://scripts/combat/last_service/transit_motion.gd").attack_phase(float(f.frame),move,float(library.street_markers[clip].contact))
        "stun":
            clip="MX_BodyHit" if f.y>.01 else "MX_HeadHit"
            reacting=true
        "blockstun":
            clip="MX_Block"
            reacting=true
        "dash":
            clip="MX_Dodge" if f.vx*f.face<0 else "MX_Run"
            phase=clampf(float(f.frame)/14.0,0.0,1.0)
        "idle":
            if f.y>.01:return {}
            var stride:=absf(float(f.vx))
            if stride<.3:
                clip="MX_Idle"
                speed=.72 if id=="foreman" else .95
            elif f.vx*f.face<0.0:
                clip="MX_WalkBack" if stride<=2.0 else "MX_RunBack"
                speed=clampf(stride/(.89 if clip=="MX_WalkBack" else 3.17),.3,2.5)
            else:
                clip="MX_Walking" if stride<=2.0 else ("MX_Run" if stride<=4.6 else "MX_Sprint")
                speed=clampf(stride/(1.23 if clip=="MX_Walking" else (2.73 if clip=="MX_Run" else 6.36)),.3,2.0)
            loops=true
            guard=f.guarding or id in ["bulk","static"]
        _:return {}
    if not library.clips.has(clip):return {}
    return {"owner":"deadshift_"+id,"clip":clip,"phase":phase,"speed":speed,"loop":loops,
        "plant":false,"guard_arms":guard,"stance_clip":"Punch_Enter","stance_phase":1.0,
        "imported":true,"reaction":reacting,"transit":true,"transition":f.state}
