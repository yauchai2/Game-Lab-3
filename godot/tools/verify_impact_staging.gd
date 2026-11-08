extends SceneTree
var checks: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label: String, passed: bool) -> void:
    checks.append({"name":label,"passed":passed})
    if not passed:push_error("IMPACT FAIL: "+label)
func contact(scene: Node, move: String) -> void:
    scene.start_match(true)
    scene.sim.fighters[0].x=-.6
    scene.sim.fighters[1].x=.6
    scene.sim.fighters[0].state="attack"
    scene.sim.fighters[0].move=move
    scene.sim.fighters[0].frame=scene.Simulation.MOVES[move].startup-1
    scene._physics_process(1.0/60)
func count_kind(scene: Node, kind: String) -> int:
    return scene.effects.filter(func(e:Dictionary)->bool:return e.kind==kind).size()
func run() -> void:
    var shapes=preload("res://scripts/combat/impact_shapes.gd").new()
    var valid:=true
    var opaque:=true
    var mirrored:=true
    for kind in ["swing","hit","release"]:
        for move in shapes.PROFILES:
            for frame in 6:
                for reduced in [false,true]:
                    var left: Array[Dictionary]=shapes.build(kind,move,frame/6.0,Color.CYAN,-1,reduced)
                    var right: Array[Dictionary]=shapes.build(kind,move,frame/6.0,Color.CYAN,1,reduced)
                    for i in left.size():
                        var points: PackedVector2Array=left[i].points
                        valid=valid and not Geometry2D.triangulate_polygon(points).is_empty()
                        opaque=opaque and left[i].color.a==1.0
                        for j in points.size():
                            valid=valid and points[j].is_finite() and points[j].length()<160
                            mirrored=mirrored and points[j].is_equal_approx(Vector2(-right[i].points[j].x,right[i].points[j].y))
    check("all 432 vector cels triangulate with finite bounded geometry",valid)
    check("all new cels remain fully opaque",opaque)
    check("every attack mirrors correctly after swapping sides",mirrored)
    check("jab heavy launcher and special have distinct silhouettes",shapes.build("swing","jab",0,Color.CYAN,1,false)!=shapes.build("swing","heavy",0,Color.CYAN,1,false) and shapes.PROFILES.launcher.z<-.5 and shapes.PROFILES.special.x>shapes.PROFILES.heavy.x)
    check("late attack cels break into detached fragments",shapes.build("swing","heavy",.8,Color.CYAN,1,false).size()==4)
    check("reduced effects uses fewer release polygons",shapes.build("release","heavy",.5,Color.CYAN,1,true).size()<shapes.build("release","heavy",.5,Color.CYAN,1,false).size())
    var scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    scene.set_process(false)
    scene.set_physics_process(false)
    scene.audio.muted=true
    contact(scene,"heavy")
    check("real heavy contact schedules one held core",scene.sim.hitstop==11 and scene.impact_queue.size()==1 and count_kind(scene,"hit")==1 and count_kind(scene,"release")==0)
    var damage: int=scene.sim.fighters[1].health
    check("presentation preserves heavy damage",damage==82)
    scene._process(.5)
    check("core survives a long render interval while physics is stopped",count_kind(scene,"hit")==1 and scene.effects[0].age>=.5)
    var age: float=scene.effects[0].age
    scene.pause_game()
    scene._process(.1)
    check("pause preserves pending release and core age",scene.impact_queue.size()==1 and is_equal_approx(scene.effects[0].age,age))
    scene.resume_game()
    for i in 10:scene._physics_process(1.0/60)
    check("release waits until last hitstop tick",scene.sim.hitstop==1 and count_kind(scene,"release")==0)
    scene._physics_process(1.0/60)
    check("last hitstop tick replaces core with one release",scene.sim.hitstop==0 and scene.impact_queue.is_empty() and count_kind(scene,"hit")==0 and count_kind(scene,"release")==1)
    check("horizontal contact kicks camera opposite attacker direction",scene.recoil.x<0 and scene.recoil.length()<=.19)
    scene._physics_process(1.0/60)
    check("release is emitted exactly once",count_kind(scene,"release")==1)
    scene._process(.4)
    check("release polygons expire without alpha fade",count_kind(scene,"release")==0)
    contact(scene,"launcher")
    for i in 10:scene._physics_process(1.0/60)
    check("launcher release has rising axis",scene.recoil.y<0 and scene.effects.any(func(e:Dictionary)->bool:return e.kind=="release" and e.move=="launcher"))
    contact(scene,"special")
    scene.reset_training()
    check("practice reset clears pending contact and camera kick",scene.impact_queue.is_empty() and scene.effects.is_empty() and scene.recoil==Vector2.ZERO)
    contact(scene,"heavy")
    scene.return_to_title()
    check("return to title clears pending contact",scene.impact_queue.is_empty() and scene.recoil==Vector2.ZERO)
    scene.start_match(true)
    scene._handle_event({"kind":"block","target":1,"attacker":0})
    check("block keeps shield and never produces hit release",scene.impact_queue.is_empty() and count_kind(scene,"block")==1)
    scene.start_match(true)
    scene._handle_event({"kind":"swing","target":0,"move":"jab"})
    check("whiff has attack arc without contact burst",scene.impact_queue.is_empty() and count_kind(scene,"swing")==1 and count_kind(scene,"release")==0)
    scene.start_match(true)
    scene.sim.hitstop=2
    for attacker in 2:scene._handle_event({"kind":"hit","target":1-attacker,"attacker":attacker,"move":"cross","strength":.34})
    for i in 2:scene._physics_process(1.0/60)
    check("trade retains both contact bursts",count_kind(scene,"release")==2 and scene.impact_queue.is_empty())
    scene.reduced_effects=true
    scene.recoil=Vector2(.18,0)
    scene.recoil_age=0
    scene.trauma=1
    scene._present(0)
    check("reduced effects removes both shake and camera punch",scene.camera.position.is_equal_approx(scene.base_camera))
    contact(scene,"heavy")
    scene.advance_round()
    check("new round clears queued releases",scene.impact_queue.is_empty() and scene.effects.is_empty())
    scene.start_match(false)
    scene.sim.phase="fight"
    scene.sim.ai_enabled=false
    scene.sim.fighters[0].x=-.6
    scene.sim.fighters[1].x=.6
    scene.sim.fighters[1].health=1
    scene.sim.fighters[0].state="attack"
    scene.sim.fighters[0].move="heavy"
    scene.sim.fighters[0].frame=15
    scene._physics_process(1.0/60)
    check("KO flushes contact instead of leaving held core behind result menu",scene.screen=="result" and scene.impact_queue.is_empty() and count_kind(scene,"hit")==0 and count_kind(scene,"release")==1)
    scene.queue_free()
    await process_frame
    await create_timer(.15).timeout
    var failed:=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var file:=FileAccess.open("res://../docs/evidence/impact-staging/verification.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"geometry_cels_checked":432},"  "))
    print("IMPACT_STAGING_CHECKS ",checks.size()-failed,"/",checks.size())
    quit(0 if failed==0 else 1)
