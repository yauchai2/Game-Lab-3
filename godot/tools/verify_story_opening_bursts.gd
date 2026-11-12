extends SceneTree
## Render burst endpoints with a real canvas backend; the runner must reject ERROR logs.
class BurstCanvas extends Control:
    var opening:Node3D
    var radius:=0.0
    func _draw() -> void:
        for rays in [4,6,8,10,12,18,20,26]:
            for spin in [0.0,PI*.25,14.55]:
                opening._burst(self,Vector2(640,360),radius,rays,Color.WHITE,spin)

func _initialize() -> void:call_deferred("run")
func run() -> void:
    if DisplayServer.get_name()=="headless":
        push_error("Burst regression needs a real canvas renderer, not --headless")
        quit(2)
        return
    var canvas:=BurstCanvas.new()
    canvas.opening=preload("res://scripts/combat/cinematic/story_opening.gd").new()
    root.add_child(canvas)
    # Exact glint start, nearby subpixel radii, then visible glint/impact sizes.
    var radii:=[0.0,.00001,.001,.01,.1,.5,.99,1.0,2.0,34.0,70.0,720.0]
    for radius in radii:
        canvas.radius=radius
        canvas.queue_redraw()
        await process_frame
        await RenderingServer.frame_post_draw
        print("BURST_RENDER radius=",radius)
    canvas.opening.free()
    canvas.queue_free()
    await process_frame
    print("BURST_RENDER_RESULT ",radii.size()," radii, 24 ray/spin combinations each")
    quit()
