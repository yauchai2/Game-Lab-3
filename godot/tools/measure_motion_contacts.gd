extends SceneTree
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var scene := preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    scene.set_process(false)
    scene.set_physics_process(false)
    var actor: Node3D = scene.fighters[0]
    var skeleton: Skeleton3D = actor.skeleton
    var f: Dictionary = scene.sim.fighters[0]
    f.x = 0
    f.state = "attack"
    var result: Dictionary = {}
    for move in [["jab","Punch_Jab",5],["cross","Punch_Cross",6]]:
        f.move = move[0]
        f.frame = move[2]
        var samples: Array[Dictionary] = []
        for i in range(2,9):
            var phase := float(i)*0.1
            actor.motions.contact_phases[move[1]] = phase
            for tick in 10: actor.present(f,1.0/60.0,false,true)
            var left := skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("mixamorig_LeftHand")).origin)
            var right := skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("mixamorig_RightHand")).origin)
            samples.append({"phase":phase,"forward_reach":maxf(left.x,right.x)})
        result[move[1]] = samples
    var file := FileAccess.open("res://../docs/evidence/playtest-fixes/contact-reach.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(result,"  "))
    file.close()
    print(JSON.stringify(result))
    scene.queue_free()
    await process_frame
    quit()
