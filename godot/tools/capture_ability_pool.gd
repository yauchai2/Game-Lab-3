extends SceneTree
const OUT="res://../docs/evidence/ability-draw/expanded-pool/"
const Rewards=preload("res://scripts/combat/ability_draw/rewards.gd")
var s:Node
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("CORE_VISUAL ",label," ",ok)
    if not ok:push_error(label)
func run() -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.progression_path="/tmp/pool-capture.cfg";root.add_child(s)
    s.set_process(false);s.set_physics_process(false);s.audio.muted=true
    await process_frame;await process_frame
    s.start_match(false);s.round_theatre.clear();s.sim.round_number=2;s.sim.wins=[1,1];s.sim.phase="round_over";s.sim.winner=0;s.screen="result";s.advance_round()
    var d=s.ability_draw
    for entry in Rewards.ITEMS:
        d.result=entry.duplicate();d.result.boundary="visual-fixture"
        d.state="spin";d.age=1.50;d.source_age=3.48;d.advance(0,false);s.hud.queue_redraw()
        await process_frame;await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(OUT+entry.id+"-reels.png")
        check(entry.id+" winning reel texture and stop agree",d.actors.reel_materials.all(func(m):return m.albedo_texture.resource_path.ends_with("reels_"+entry.id+".png")) and d.actors.reels.all(func(r):return is_equal_approx(fposmod(r.rotation.x,TAU),fposmod(-TAU*.875,TAU))))
        d.state="result";d.age=.5;d.input_armed=true;d.advance(0,false);s.hud.queue_redraw()
        await process_frame;await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(OUT+entry.id+"-result.png")
        check(entry.id+" capsule tint icon and readable action agree",d.actors.reward_body.material_override.albedo_color==entry.color and d.actors.reward_icon.material_override.albedo_texture.resource_path.ends_with("/"+entry.id+".png") and d.action.visible and not d.action.disabled)
    s.return_to_title();s.start_match(false);s.round_theatre.clear();s.sim.phase="fight";s.sim.ai_enabled=false;s.screen="play"
    var item:Dictionary=Rewards.item("eco");item.boundary="hud-fixture";s.draw_rewards.apply_once(s.sim,item);s._process(0);s.hud.queue_redraw()
    await process_frame;await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(OUT+"eco-combat-hud.png")
    check("ECO HUD thresholds use actual 40 and 60 costs",s.sim.skill_cost(s.sim.fighters[0],"special")==40 and s.sim.skill_cost(s.sim.fighters[0],"overdrive")==60)
    s.return_to_title();s.audio.set_process(false);s.audio.music.stop();s.audio.fading_music.stop()
    await create_timer(.15).timeout;s.queue_free();s=null
    for i in 8:await process_frame
    var failed:int=checks.filter(func(c):return not c.passed).size()
    FileAccess.open(OUT+"core-visuals.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"scope":"Forced catalog fixture; actual 3D reels/core colors/icons/GUI and combat HUD render, not a random-drop recording."},"  "))
    print("CORE_VISUAL_CHECKS ",checks.size()-failed,"/",checks.size());quit(1 if failed else 0)
