extends Node3D
## F6 from nightshift_workshop.tscn: a clean art preview without campaign/save mutations.
func _ready() -> void:
    var set_model:=preload("res://scripts/combat/city/nightshift/workshop.gd").new();add_child(set_model);set_model.build()
    for i in 4:
        var actor:=preload("res://scripts/combat/fighter_visual.gd").new();actor.neon_enabled=true;add_child(actor);actor.setup(Color.WHITE,i)
        actor.position=[Vector3(0,0,1.5),Vector3(-3.25,0,-3.1),Vector3(-7,2.1,-3.8),Vector3(.2,0,-3.6)][i];actor.rotation.y=.5;actor.scale=Vector3.ONE*.9
        actor.motions.present({"character":i,"health":100,"state":"idle","move":"","frame":0,"x":0.0,"y":0.0,"vx":0.0,"vy":0.0,"face":1,"guarding":false,"showcase":true},0.0,true)
