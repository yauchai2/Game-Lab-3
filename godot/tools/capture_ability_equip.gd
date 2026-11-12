extends SceneTree
const OUT="res://../docs/evidence/ability-equip/"
const Rewards=preload("res://scripts/combat/ability_draw/rewards.gd")
var s:Node
func _initialize() -> void:call_deferred("run")
func run() -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.progression_path="/tmp/equip-capture.cfg";root.add_child(s)
    s.character_choices[0]=0;s.start_match(false);s.audio.muted=false;s.audio.music_muted=true;s.reduced_effects=false;s.round_theatre.clear()
    s.sim.round_number=2;s.sim.wins=[1,1];s.sim.phase="round_over";s.sim.winner=0;s.screen="result";s.advance_round()
    var d=s.ability_draw;d.arrival.stop();d.state="result";d.age=0;d.result=Rewards.item("speed");d.result.boundary=s.ability_draw_boundary()
    var clicks:=false;var transitions:Array=[];var previous:="";var end_frames:=0;var start_frame:=Engine.get_process_frames()
    for tick in 220:
        await process_frame
        if d.state=="result" and d.age>=1.0 and not clicks:
            clicks=true
            var point:Vector2=d.action.get_global_rect().get_center()
            for down in [true,false]:
                var e:=InputEventMouseButton.new();e.position=point;e.global_position=point;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;root.push_input(e,true);await process_frame
        if previous!=d.state:previous=d.state;transitions.append({"state":d.state,"time":float(Engine.get_process_frames()-start_frame)/30})
        if d.state=="off":
            end_frames+=1
            if end_frames>=24:break
    FileAccess.open(OUT+"capture.json",FileAccess.WRITE).store_string(JSON.stringify({"transitions":transitions,"scope":"Forced SPEED award boundary, then real GUI click, actual 3D equip and round-three claim. Not a natural full match."},"  "))
    s.return_to_title();s.set_process(false);s.set_physics_process(false);s.audio.set_process(false);s.audio.music.stop();s.audio.fading_music.stop()
    await create_timer(.20).timeout;s.queue_free();s=null
    for i in 12:await process_frame
    quit()
