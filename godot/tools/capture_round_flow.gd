extends SceneTree
## Actual engine title -> entry -> normal-health autonomous fight -> full KO -> loop.
const OUT="res://../docs/evidence/round-flow/"
var s:Node
var events:Dictionary={}
var shots:Dictionary={}
var max_seconds:=100.0
func _initialize() -> void:call_deferred("run")
func run() -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.progression_path="/tmp/round-flow-capture.cfg"
    root.add_child(s);s.audio.muted=false;s.audio.music_muted=true;s.reduced_effects=false
    s.combat_event.connect(func(e:Dictionary):events[e.kind]=events.get(e.kind,0)+1)
    await create_timer(.6).timeout
    s.start_demo();var clock:=0.0
    while clock<max_seconds:
        await process_frame
        clock+=1.0/30
        var label:=""
        if s.round_theatre.intro:
            if s.round_theatre.age>.7 and s.round_theatre.age<1.0:label="p1-entry"
            elif s.round_theatre.age>1.4 and s.round_theatre.age<1.7:label="p2-entry"
            elif s.round_theatre.age>2.2:label="round-entry"
        elif s.city_breaker.active():
            if s.city_breaker.playback_elapsed>5.4:label="winner"
            elif s.city_breaker.playback_elapsed>3.6:label="smoke-explosion"
        elif s.round_theatre.lens.visible:label="combat-fisheye"
        elif s.sim.phase=="fight" and clock>5:label="street-smoke"
        if label!="" and not shots.has(label):
            shots[label]=clock
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png(OUT+label+".png")
        if s.demo.rounds_finished>=2 and s.round_theatre.age>.6:break
    FileAccess.open(OUT+"capture.json",FileAccess.WRITE).store_string(JSON.stringify({"seconds":clock,"rounds_completed":s.demo.rounds_finished,"real_ko_events":events.get("ko",0),"events":events,"shots":shots,"scope":"Actual unmodified-stat AI Demo. Full title, entries, KO and winner sequences followed by next-round loop; no injected hits."},"  "))
    s.return_to_title();s.set_process(false);s.set_physics_process(false);s.audio.set_process(false);s.audio.music.stop();s.audio.fading_music.stop()
    await create_timer(.15).timeout;s.queue_free();s=null
    for i in 8:await process_frame
    quit()
