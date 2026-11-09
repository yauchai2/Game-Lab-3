extends SceneTree
class Preview extends Node2D:
    var texture:Texture2D
    var bounds:=Rect2(0,0,1536,1024)
    func _draw() -> void:
        for y in 32:
            for x in 48:draw_rect(Rect2(x*32,y*32,32,32),Color("d7dbe1") if (x+y)%2==0 else Color("f4f1e8"))
        if texture:draw_texture_rect(texture,bounds,false)
func _initialize() -> void:call_deferred("run")
func run() -> void:
    var preview:=Preview.new();root.add_child(preview);current_scene=preview
    var logical:Vector2=root.get_visible_rect().size
    preview.scale=Vector2.ONE*minf(logical.x/1536.0,logical.y/1024.0)
    preview.position=(logical-Vector2(1536,1024)*preview.scale)*.5
    for spec in [["ui-frames",Rect2(0,0,1536,1024)],["action-icons",Rect2(288,32,960,960)],["afterhours-logo",Rect2(32,240,1472,503)]]:
        var path:String=ProjectSettings.globalize_path("res://../references/ui-jsr-2026-11-09/assets/"+spec[0]+".png")
        var img:=Image.load_from_file(path);preview.texture=ImageTexture.create_from_image(img);preview.bounds=spec[1];preview.queue_redraw()
        await process_frame;await process_frame;await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://../docs/evidence/ui-jsr/"+spec[0]+"-alpha-preview.png")
    preview.queue_free();await process_frame;call_deferred("quit")
