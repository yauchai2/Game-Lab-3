extends SceneTree
var s:Node
var checks:Array=[]
const OUT="res://../docs/evidence/black-suit-squad/"
func _initialize() -> void:call_deferred("run")
func frames(n:=3) -> void:
    for frame in n:await process_frame
func check(name:String,passed:bool) -> void:
    checks.append({"name":name,"passed":passed});print("SQUAD_NATIVE ",name," ",passed)
func shot(label:String) -> void:
    s.hud.queue_redraw();await frames();await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(OUT+label+".png")
func run() -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.progression_path=""
    root.add_child(s);s.set_process(false);s.set_physics_process(false);s.audio.muted=true
    s.hud.open_page("roster");await frames()
    var button:Control=s.hud.art_buttons.enemy_squad
    for pressed in [true,false]:
        var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=root.get_screen_transform()*button.get_global_rect().get_center();e.global_position=e.position;e.pressed=pressed;Input.parse_input_event(e);await frames(2)
    check("real pointer starts squad encounter",s.sim.squad_enabled and s.squad_visuals.size()==4 and s.screen=="play")
    check("squad keeps multiplayer view without duel intro or ability draw",not s.round_theatre.intro and s.ability_draw_boundary().is_empty())
    for step in 60:s._process(1.0/60)
    await shot("squad-start")
    var mapped:=true
    for visual in s.squad_visuals:
        mapped=mapped and visual.motions.mapping.size()==52 and visual.skeleton.get_bone_count()==65 and visual.materials.size()>=1
    check("all black suit enemies have valid shared rigs and materials",mapped)
    var hp:int=s.sim.fighters[0].health
    s.pause_game();var clock:int=s.sim.tick_count
    for step in 30:s._physics_process(1.0/60);s._process(1.0/60)
    check("pause freezes the whole squad",s.sim.tick_count==clock and s.sim.fighters[0].health==hp)
    s.resume_game();s.sim.phase="fight"
    for step in 900:
        var command:Dictionary=s.sim.rush_agent.choose(s.sim,0,s.sim.ai_tick,1)
        s.pending=command.duplicate();s.pending["attack"]=command.get("attack","light")
        s._physics_process(1.0/60);s._process(1.0/60)
        if step==150:await shot("squad-action")
        if step%120==0:await frames(1)
        if s.screen=="result":break
    await shot("squad-result")
    check("no squad action grants hero mastery",s.growth.records.zip.xp==0)
    s.pause_game();s.start_squad();await frames()
    check("restart recreates exactly one squad",s.squad_visuals.size()==4 and s.sim.squad_members.size()==4)
    s.return_to_title();await frames(8)
    check("return to menu removes group visuals and simulation",s.squad_visuals.is_empty() and not s.sim.squad_enabled and s.sim.fighters.size()==2)
    s.start_demo();await frames()
    check("demo keeps original two-person simulation",s.demo!=null and not s.sim.squad_enabled and s.fighters.size()==2)
    s.return_to_title();s.start_squad();s.pause_game();s.start_match(false);await frames(8)
    check("ordinary fight clears the group",not s.sim.squad_enabled and s.squad_visuals.is_empty())
    s.return_to_title();s.queue_free();s=null;await frames(8)
    check("materials retire after group teardown",preload("res://scripts/combat/fighter_visual.gd").retired_materials.is_empty())
    FileAccess.open(OUT+"native.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"scope":"Linux Compatibility pointer/UI/model render and lifecycle checks. Automated command sample is not a human playtest."},"  "))
    await create_timer(.3).timeout;call_deferred("quit",0 if checks.all(func(c:Dictionary)->bool:return c.passed) else 1)
