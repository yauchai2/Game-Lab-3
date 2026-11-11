extends SceneTree
## Deliberate second-round boundary fixture; actual 3D render, audio and UI.
const OUT="res://../docs/evidence/ability-draw/entry-v2/"
var s:Node
var live:=false
var output:=OUT
func _initialize() -> void:call_deferred("run")
func run() -> void:
    live="--live" in OS.get_cmdline_user_args()
    if "--tripo-models" in OS.get_cmdline_user_args():output="res://../docs/evidence/ability-draw/tripo-models/"
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.progression_path="/tmp/draw-capture.cfg";root.add_child(s)
    s.audio.muted=false;s.audio.music_muted=true;s.reduced_effects=false
    s.start_match(false);s.round_theatre.clear();s.sim.round_number=2;s.sim.wins=[1,1];s.sim.phase="round_over";s.sim.winner=0;s.screen="result";s.result_clock=2;s.draw_seed=42
    s.advance_round()
    if live:return
    var shots:Dictionary={};var ticks:=0;var result_frames:=0
    while ticks<230:
        await process_frame;ticks+=1
        var d=s.ability_draw
        if d.state=="offer" and d.age>=.40:d.confirm()
        if d.state=="result":result_frames+=1
        var label:=""
        if d.state=="arrival":
            if d.source_age<.10:label="00-empty"
            elif d.source_age>.62 and d.source_age<.8:label="01-entry"
            elif d.source_age>1.08 and d.source_age<1.22:label="02-landing"
            elif d.source_age>1.40 and d.source_age<1.6:label="03-slap"
        elif d.state=="offer":label="04-offer"
        elif d.state=="spin":
            if d.source_age<3.05:label="05-reels"
            elif d.source_age>=3.43 and d.source_age<3.5:label="06-lock"
            elif d.source_age>3.65:label="07-jackpot"
        elif d.state=="result":label="08-core"
        if label!="" and not shots.has(label):
            shots[label]=ticks/30.0;await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png(output+label+".png")
        if result_frames>=45:break
    var item:Dictionary=s.ability_draw.result.duplicate()
    FileAccess.open(output+"capture.json",FileAccess.WRITE).store_string(JSON.stringify({"shots":shots,"seconds":ticks/30.0,"reward":item,"scope":"Explicit second-round 1-1 boundary fixture. Actual game scene, 3D NPC, machine, shader FX and original sound. Not a natural-match recording or target hardware benchmark."},"  "))
    s.return_to_title();s.set_process(false);s.set_physics_process(false);s.audio.set_process(false);s.audio.music.stop();s.audio.fading_music.stop()
    await create_timer(.1).timeout;s.queue_free();s=null
    for i in 8:await process_frame
    quit()
