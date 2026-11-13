extends SceneTree
## Native capture of the Black Suit pistol sequence (windup, warning, muzzle, flight, impact, block, deflect).
## xvfb-run -a godot --rendering-driver opengl3 --path godot --script res://tools/capture_gun_shot.gd
const OUT="res://../docs/evidence/black-suit-gun/"
var s:Node
func _initialize() -> void:call_deferred("run")
func frames(n:=2) -> void:
    for i in n:await process_frame
func shot(label:String) -> void:
    s.hud.queue_redraw();await frames();await RenderingServer.frame_post_draw
    var err:=root.get_texture().get_image().save_png(OUT+label+".png")
    print("CAPTURE ",label," ",err)
func setup(hero_x:float) -> void:
    s.start_match(false)
    s.sim.phase="fight";s.sim.ai_enabled=false;s.sim.countdown=0;s.audio.muted=true
    s.sim.fighters[0].x=hero_x;s.sim.fighters[1].x=2.5
    s.sim.fighters[0].face=1;s.sim.fighters[1].face=-1
    s.sim._start_attack(1,"gun")
func step(cmd:Dictionary={}) -> void:
    s.sim.tick(cmd)
    for event in s.sim.events:s._handle_event(event)
    s._process(1.0/60);
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    var options_path:="/tmp/gun-test-options.cfg"
    var prefs=preload("res://scripts/combat/fight_preferences.gd").new()
    prefs.write_options(options_path,{"player_character":2,"rival_character":4})
    s=preload("res://scenes/combat/street_fight.tscn").instantiate()
    s.preferences_path=options_path;s.progression_path=""
    root.add_child(s);s.set_process(false);s.set_physics_process(false)
    await frames(3)
    # A) full hit sequence
    setup(-4.0)
    var marks:={10:"01-windup",27:"02-warning",31:"03-muzzle",36:"04-flight"}
    for t in 90:
        step()
        if marks.has(t):await shot(marks[t])
        if not s.sim.events.is_empty() and s.sim.events.any(func(e:Dictionary)->bool:return e.kind=="gun_hit"):
            await shot("05-hit");break
    # B) block
    setup(-4.0)
    for t in 100:
        step({"guard":true})
        if s.sim.events.any(func(e:Dictionary)->bool:return e.kind=="gun_block"):await shot("06-block");break
    # C) deflect
    setup(-4.0);var pressed:=false
    for t in 100:
        var cmd:Dictionary={}
        if not s.sim.projectiles.is_empty() and absf(s.sim.projectiles[0].x-s.sim.fighters[0].x)<2.4 and not pressed:cmd={"guard":true,"guard_pressed":true};pressed=true
        elif pressed:cmd={"guard":true}
        step(cmd)
        if s.sim.events.any(func(e:Dictionary)->bool:return e.kind=="gun_deflect"):await shot("07-deflect");break
    quit()
