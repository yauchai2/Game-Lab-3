extends SceneTree
## D3: SURGE tier 3 triggers one visual aircraft pass with cooldown; F2/training/frozen suppress it.
var checks:Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,value:bool) -> void:
    checks.append({"name":label,"passed":value})
    if not value:push_error("FLYBY EVENT FAIL: "+label)
func run() -> void:
    var scene=load("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene);current_scene=scene
    scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true
    var b=scene.backdrop
    scene.start_match(false)
    b.elapsed=10.0;b.flyby_cooldown=0.0
    check("request starts a pass at the beginning of the flight window",b.request_flyby() and fposmod(b.elapsed+b.FLIGHT_SECONDS*0.5,b.cycle)<0.01)
    check("cooldown blocks a second pass",not b.request_flyby())
    b.present(1.0,false,false)
    check("plane is visible during the pass",b.plane.visible)
    b.flyby_cooldown=0.0
    b.frozen=true
    check("frozen backdrop refuses",not b.request_flyby())
    b.frozen=false
    # Session tier-up hook (called when pressure crosses into tier 3)
    scene.sim.phase="fight";scene.sim.exchange.pressure=61.0
    b.flyby_cooldown=0.0;scene._tier_up_feedback()
    check("tier 3 in a standard fight triggers the pass",b.flyby_cooldown>30.0)
    b.flyby_cooldown=0.0;scene.reduced_effects=true;scene._tier_up_feedback()
    check("F2 reduced effects suppresses it",b.flyby_cooldown==0.0)
    scene.reduced_effects=false;scene.sim.exchange.pressure=45.0;scene._tier_up_feedback()
    check("tier 2 does not trigger it",b.flyby_cooldown==0.0)
    scene.sim.exchange.pressure=61.0;scene.start_match(true);scene._tier_up_feedback()
    check("training suppresses it",b.flyby_cooldown==0.0)
    var failed:=checks.filter(func(c):return not c.passed)
    print("FLYBY EVENT: %d/%d checks passed"%[checks.size()-failed.size(),checks.size()])
    quit(1 if not failed.is_empty() else 0)
