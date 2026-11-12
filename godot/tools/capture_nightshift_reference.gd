extends SceneTree
var s:Node
var h:Node
var ready_to_capture:=false
var frame:=0
func _initialize() -> void:call_deferred("run")
func run() -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.city_save_path="user://reference-capture/profile.json";s.story_opening_on_boot=false
    root.add_child(s);s.audio.muted=true;s.set_process(false);s.set_physics_process(false)
    for i in 6:await process_frame
    s.city_campaign.open_city();h=s.city_campaign.hub;h.set_process(false);h.layout.hide()
    h._avatar(.12,Vector2.ZERO) # Warm all three companion rigs before the first recorded frame.
    ready_to_capture=true
func _process(_delta:float) -> bool:
    if not ready_to_capture:return false
    var time:float=float(frame)/30.0
    h.workshop.pulse_time=time;h._avatar(1.0/30,Vector2.ZERO);h.workshop.sample(time,false)
    if frame in [0,45,165,240,315,435]:
        call_deferred("save_frame",frame)
    frame+=1
    if frame>=450:
        ready_to_capture=false;call_deferred("done")
    return false
func save_frame(number:int) -> void:
    await RenderingServer.frame_post_draw
    h.viewport.get_texture().get_image().save_png("res://../docs/evidence/nightshift-reference/capture-%04d.png"%number)
func done() -> void:
    await process_frame;s.queue_free();await process_frame;quit()
