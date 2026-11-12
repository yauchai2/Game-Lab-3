extends Node3D
## Reusable cinematic/background actor. No AI, collision, damage, XP or input polling.
## Root transform belongs to the scene/director; only the child visual is animated.
const Visual=preload("res://scripts/combat/fighter_visual.gd")
@export_enum("idle","walk","guard") var posture:String="idle"
@export var animation_enabled:=true
@export var neon_enabled:=true
var visual:Node3D

func _ready() -> void:
    visual=Visual.new()
    visual.name="Visual"
    visual.neon_enabled=neon_enabled
    add_child(visual)
    visual.setup(Color.WHITE,Visual.Roster.BLACK_SUIT_INDEX)
    advance(0.0)

func _process(delta:float) -> void:
    if animation_enabled:advance(delta)

func advance(delta:float) -> void:
    if not is_instance_valid(visual):return
    var pose:Dictionary={"character":Visual.Roster.BLACK_SUIT_INDEX,"health":100,"state":"idle","move":"","frame":0,"x":0.0,"y":0.0,"vy":0.0,"vx":2.0 if posture=="walk" else 0.0,"face":1,"flash":0,"guarding":posture=="guard","showcase":posture=="idle"}
    visual.present(pose,delta,false,true)
    if posture=="idle":
        var m=visual.motions
        for side in ["Left","Right"]:
            m._aim_limb(side+"Arm",side+"ForeArm",-m.model_up+m.model_forward*.1,.95)
            m._aim_limb(side+"ForeArm",side+"Hand",-m.model_up+m.model_forward*.15,.95)
    # FighterVisual normally owns combat coordinates; actors stay at their authored origin.
    visual.position=Vector3.ZERO
    visual.rotation=Vector3.ZERO
