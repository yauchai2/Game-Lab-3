extends Node3D
## Shared physical module for the cinematic and live fighter. No source GLB edits.
const Geometry=preload("res://scripts/combat/ability_draw/visuals.gd")
const Rewards=preload("res://scripts/combat/ability_draw/rewards.gd")
var capsule:Node3D
var clips:Array[Node3D]=[]
var lamp:MeshInstance3D
var color:=Color.WHITE
var core_id:=""
func build(id:String) -> void:
    core_id=id;color=Rewards.item(id).get("color",Color("44ffdd"))
    var g:=Geometry.new();add_child(g)
    capsule=Node3D.new();add_child(capsule)
    g.cylinder(capsule,Vector3.ZERO,.19,.63,color,6,-1,true)
    for y in [-.37,.37]:g.cylinder(capsule,Vector3(0,y,0),.25,.14,Color("ded1a8"),6,-1,true)
    var glyph:=g.icon(capsule,"pool/"+id,Vector3(0,0,.204),Vector2(.29,.44))
    glyph.name="CoreBodySymbol"
    var cap:=g.icon(capsule,"pool/"+id,Vector3(0,.446,0),Vector2(.30,.30));cap.rotation.x=-PI/2
    g.box(g,Vector3(0,0,-.025),Vector3(.30,.31,.065),Color("18191f"),true)
    lamp=g.box(g,Vector3(.13,0,.018),Vector3(.025,.15,.025),color,false,true)
    for sign_y in [-1,1]:
        var clip:=Node3D.new();g.add_child(clip);clips.append(clip)
        g.box(clip,Vector3(0,0,.06),Vector3(.25,.045,.15),Color("ffae38"),true)
    capsule.transform=Transform3D(Basis(Vector3.RIGHT,PI/2).scaled(Vector3.ONE*.40),Vector3(0,0,.10))
    pose_clips(1,true)
func pose_clips(locked:float,powered:bool) -> void:
    for i in 2:clips[i].position.y=(-1 if i==0 else 1)*lerpf(.24,.125,locked)
    lamp.visible=powered
static func socket_frame(hero:Node3D) -> Transform3D:
    var sk:Skeleton3D=hero.skeleton;var hips:int=hero.motions.bone_index("Hips")
    var rest:Transform3D=sk.get_bone_global_rest(hips)
    var now:Transform3D=sk.global_transform*sk.get_bone_global_pose(hips)
    var socket_basis:Basis=now.basis.orthonormalized()*rest.basis.orthonormalized().inverse()*sk.global_basis.orthonormalized().inverse()*hero.model.global_basis.orthonormalized()
    var right_leg:int=hero.motions.bone_index("RightUpLeg")
    var side:float=signf((sk.to_global(sk.get_bone_global_pose(right_leg).origin)-now.origin).dot(socket_basis.x))
    var scale_factor:float=hero.model_scale/2.1
    return Transform3D(socket_basis,now.origin+socket_basis*Vector3(side*.24,-.075,.15)*scale_factor)
