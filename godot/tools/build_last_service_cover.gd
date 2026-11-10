extends SceneTree
## Deterministic engine-rendered poster from the actual new GLBs; no baked UI controls.
var s:Node
func _initialize() -> void:call_deferred("run")
func run() -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.progression_path="/tmp/cover-growth.cfg";root.add_child(s)
    s.set_process(false);s.set_physics_process(false);s.audio.muted=true;s.hud.hide();s.backdrop.freeze_for_capture()
    s.set_character(0,0);s.set_character(1,2)
    for i in 2:
        var visual:Node3D=s.fighters[i]
        visual.position=Vector3(2.35+i*.60,0,3.0);visual.rotation.y=-.25 if i==0 else .18
        var m=visual.motions
        m.present({"character":[0,2][i],"health":100,"state":"idle","move":"","frame":0,"y":0.0,"vy":0.0,"vx":0.0,"guarding":false},.1,false)
        for side in ["Left","Right"]:
            m._aim_limb(side+"Arm",side+"ForeArm",-m.model_up+m.model_forward*.10,1.0)
            m._aim_limb(side+"ForeArm",side+"Hand",-m.model_up+m.model_forward*.35,1.0)
        for material in visual.materials:
            material.set_shader_parameter("silhouette_preview",true);material.set_shader_parameter("tint",Color("00d6d8") if i==0 else Color("ff459d"))
            if material.next_pass:material.next_pass.set_shader_parameter("silhouette_preview",true)
    s.camera.projection=Camera3D.PROJECTION_ORTHOGONAL;s.camera.size=1.25;s.camera.position=Vector3(2.0,1.68,7);s.camera.look_at(Vector3(2.0,1.68,3))
    var canvas:=CanvasLayer.new();root.add_child(canvas)
    var left:=ColorRect.new();left.color=Color("08090d");left.position=Vector2.ZERO;left.size=Vector2(255,360);canvas.add_child(left)
    for frame in 8:await process_frame
    await RenderingServer.frame_post_draw
    DirAccess.make_dir_recursive_absolute("res://assets/ui/last_service")
    root.get_texture().get_image().save_png("res://assets/ui/last_service/cover.png")
    s.queue_free();canvas.queue_free();s=null
    for frame in 4:await process_frame
    await RenderingServer.frame_post_draw
    await create_timer(.3).timeout
    call_deferred("quit")
