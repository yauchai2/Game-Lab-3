extends SceneTree
## Round-ending KO flight: victim is launched away, tumbles, lands, bounces and
## slides to rest, while the simulation snapshot stays untouched.
var checks: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label: String, passed: bool) -> void:
    checks.append({"name":label,"passed":passed})
    if not passed:push_error("KO TUMBLE FAIL: "+label)
func run() -> void:
    var shots:String=OS.get_environment("KO_SHOTS")
    var scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    scene.set_process(false);scene.set_physics_process(false)
    scene.audio.muted=true
    scene.start_match(false)
    scene.sim.ai_enabled=false
    scene.sim.phase="fight"
    scene.sim.fighters[0].x=-1.0;scene.sim.fighters[1].x=0.2
    for f in scene.sim.fighters:
        f.y=0.0;f.flash=15;f.vx=0
    scene.sim.fighters[1].health=0;scene.sim.fighters[1].state="stun";scene.sim.fighters[1].stun=30
    scene._physics_process(1.0/60)
    check("round KO enters result without ending the match",scene.screen=="result" and scene.sim.phase=="round_over" and not scene.final_ko())
    check("round KO starts the tumble for the loser",scene.ko_tumble.active() and scene.ko_tumble.victim==1)
    var snapshot:Array=scene.sim.fighters.duplicate(true)
    var start_x:float=scene.sim.fighters[1].x
    var max_y:=0.0;var max_spin:=0.0
    var beats:Array=[]
    var frames:=0
    for i in 100:
        scene._process(1.0/60);scene.hud._process(1.0/60)
        frames+=1
        var v:Node3D=scene.fighters[1]
        max_y=maxf(max_y,v.position.y)
        max_spin=maxf(max_spin,absf(v.model.rotation.x))
        if shots!="" and DisplayServer.get_name()!="headless" and i%6==0:
            await process_frame;await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png("%s/ko_%03d.png"%[shots,i])
    var v:Node3D=scene.fighters[1]
    var travelled:float=absf(v.position.x-start_x)
    check("loser is knocked a real distance away (%.2f)"%travelled,travelled>2.0)
    check("loser is knocked away from the winner",signf(v.position.x-start_x)==signf(start_x-scene.sim.fighters[0].x))
    check("loser arcs through the air (%.2f)"%max_y,max_y>1.0)
    check("loser tumbles mid-air (%.2f rad)"%max_spin,max_spin>1.5)
    check("loser comes to rest on the ground",is_zero_approx(v.position.y) and absf(v.model.rotation.x)<.01)
    check("loser stays inside the arena",absf(v.position.x)<=8.2)
    check("winner is not moved",is_equal_approx(scene.fighters[0].position.x,scene.sim.fighters[0].x))
    check("simulation snapshot is untouched by presentation",scene.sim.fighters==snapshot)
    # Reduced effects: legacy in-place behaviour, no tumble.
    scene.reduced_effects=true
    scene.start_match(false)
    scene.sim.phase="fight";scene.sim.ai_enabled=false
    scene.sim.fighters[1].health=0
    scene._physics_process(1.0/60)
    check("reduced effects skip the tumble",not scene.ko_tumble.active())
    scene.audio.set_process(false);scene.audio.music.stop();scene.audio.fading_music.stop()
    scene.queue_free()
    for i in 4:await process_frame
    var failed:=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    print("KO_TUMBLE_CHECKS ",checks.size()-failed,"/",checks.size())
    quit(0 if failed==0 else 1)
