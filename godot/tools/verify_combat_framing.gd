extends SceneTree
var checks: Array[Dictionary]=[]
var samples: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label: String, passed: bool) -> void:
    checks.append({"name":label,"passed":passed})
    if not passed:push_error("FRAMING FAIL: "+label)
func run() -> void:
    var scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    scene.set_process(false)
    scene.set_physics_process(false)
    scene.audio.muted=true
    scene.start_match(true)
    for pair in [[-8.2,-7.4],[-8.2,8.2],[-3.0,3.0],[-.4,.4],[7.4,8.2]]:
        for air in [0.0,2.1]:
            for i in 2:
                scene.sim.fighters[i].x=pair[i]
                scene.sim.fighters[i].y=air if i==0 else 0.0
            for i in 6:scene._present(1.0)
            var safe:=true
            var points: Array[Vector2]=[]
            for fighter in scene.sim.fighters:
                for height in [0.0,2.4]:
                    var at: Vector2=scene.project(Vector2(fighter.x,fighter.y+height))
                    points.append(at)
                    safe=safe and at.x>26 and at.x<1254 and at.y>110 and at.y<585
            samples.append({"positions":pair,"jump_height":air,"projected_body_extents":str(points),"camera":str(scene.camera.position),"safe":safe})
            check("both bodies fit above the pressure HUD at %s / air %.1f"%[pair,air],safe)
    scene.sim.fighters[0].x=-.8
    scene.sim.fighters[0].y=0
    scene.sim.fighters[1].x=.8
    for i in 6:scene._present(1.0)
    var foot: Vector2=scene.project(Vector2(-.8,0))
    var head: Vector2=scene.project(Vector2(-.8,2.1))
    check("close-range fighter silhouette occupies at least 145 logical pixels",foot.y-head.y>145)
    var before: Vector3=scene.camera.position
    scene.sim.fighters[0].x+=.5
    scene.sim.fighters[1].x+=.5
    scene._present(1.0/60)
    check("following a half-metre step eases rather than teleports",scene.camera.position.distance_to(before)>.001 and scene.camera.position.distance_to(before)<.15)
    scene.pause_game()
    before=scene.camera.global_position
    scene._process(.1)
    check("pause holds framing in place",scene.camera.global_position.is_equal_approx(before))
    scene.queue_free()
    await process_frame
    await create_timer(.15).timeout
    var failed:=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var file:=FileAccess.open("res://../docs/evidence/extended-polish/framing/verification.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"checks":checks,"samples":samples,"passed":checks.size()-failed,"failed":failed,"method":"perspective-projected 2.4 m fighter envelope; not a human camera-comfort test"},"  "))
    print("FRAMING_CHECKS ",checks.size()-failed,"/",checks.size())
    quit(0 if failed==0 else 1)
