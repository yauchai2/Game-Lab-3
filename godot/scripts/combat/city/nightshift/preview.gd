extends Node3D
## F6: calibrated fixed-camera set with real actors, no save/transaction writes.
var set_model:Node3D
var actors:Array[Node3D]=[]
var sample_clock:=0.0
func _ready() -> void:
    set_model=preload("res://scripts/combat/city/nightshift/reference_workshop.gd").new();add_child(set_model);set_model.build()
    for i in 4:
        var actor:=preload("res://scripts/combat/fighter_visual.gd").new();actor.neon_enabled=true;add_child(actor);actor.setup(Color.WHITE,i)
        actor.position=set_model.spawns[i];actors.append(actor)
    _actors(.1)
func _process(delta:float) -> void:
    set_model.advance(delta,false);sample_clock+=delta
    if sample_clock>=1.0/12:_actors(sample_clock);sample_clock=0.0
func _actors(delta:float) -> void:
    for i in actors.size():
        var actor:Node3D=actors[i]
        actor.motions.present({"character":i,"health":100,"state":"idle","move":"","frame":0,"x":0.0,"y":0.0,"vx":0.0,"vy":0.0,"face":1,"guarding":false,"showcase":true,"shared_profile":true},delta,true)
        set_model.pose_actor(actor,i,false,false)
