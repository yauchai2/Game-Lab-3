extends SceneTree
const OUT="res://../docs/evidence/ability-draw/expanded-pool/"
var s:Node
func _initialize() -> void:call_deferred("run")
func run() -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.progression_path="/tmp/demo-pool-capture.cfg";root.add_child(s)
    s.start_demo();s.audio.muted=false;s.audio.music_muted=true;s.reduced_effects=false
    s.round_theatre.clear();s.sim.round_number=2;s.sim.wins=[1,1];s.sim.phase="round_over";s.sim.winner=0;s.screen="result";s.result_clock=2;s.draw_seed=3-s.draw_match_serial;s._advance_demo_round()
    var start_frame:=Engine.get_process_frames()
    var ticks:=0;var transitions:Array=[];var previous:="";var end_frames:=0
    while ticks<380:
        await process_frame;ticks+=1
        var d=s.ability_draw
        if d.state!=previous:
            previous=d.state;transitions.append({"state":previous,"time":float(Engine.get_process_frames()-start_frame)/30.0,"reward":d.result.get("id","")})
            if d.state!="off":
                await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(OUT+"demo-"+d.state+".png")
        if d.state=="off":
            end_frames+=1
            if end_frames>=20:break
    FileAccess.open(OUT+"demo-capture.json",FileAccess.WRITE).store_string(JSON.stringify({"transitions":transitions,"seconds":float(Engine.get_process_frames()-start_frame)/30.0,"reward_seed":3,"no_input_events":true,"scope":"Explicit 1-1 Demo boundary; actual automatic timed draw and claim, no synthesized key/mouse input."},"  "))
    s.return_to_title();s.set_process(false);s.set_physics_process(false);s.audio.set_process(false);s.audio.music.stop();s.audio.fading_music.stop()
    await create_timer(.1).timeout;s.queue_free();s=null
    for i in 8:await process_frame
    quit()
