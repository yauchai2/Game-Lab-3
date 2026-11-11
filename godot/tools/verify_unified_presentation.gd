extends SceneTree
const OUT="res://../docs/evidence/unified-pixel/"
var s:Node
var checks:Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,passed:bool,detail:Variant=null) -> void:
    checks.append({"check":label,"pass":passed,"detail":detail});print("PIXEL ",label," ",passed)
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";root.add_child(s)
    s.set_process(false);s.set_physics_process(false);s.audio.muted=true
    for i in 5:await process_frame
    check("Shared framebuffer 640x360",root.get_texture().get_size()==Vector2(640,360),str(root.get_texture().get_size()))
    check("World-only pixel filter retired",not s.pixel_pass.visible)
    s.hud.open_page("roster")
    var preview:Node=s.hud.roster_preview
    var pose_signatures:Array=[]
    for choice in 4:
        s.set_character(0,choice)
        for i in 10:preview.update_preview(true,choice,1.0/15,false);await process_frame
        var actor:Node3D=preview.models[4]
        pose_signatures.append(str(actor.skeleton.get_bone_pose_rotation(actor.skeleton.find_bone("mixamorig_RightArm"))))
        check("Live hero selection "+str(choice),actor.character_index==choice and actor.skeleton!=null)
        await shot("roster"+str(choice))
    check("Four different pose rotations",pose_signatures[0]!=pose_signatures[1] and pose_signatures[1]!=pose_signatures[2] and pose_signatures[2]!=pose_signatures[3],pose_signatures)
    for i in 24:preview.update_preview(true,i%4,.08,false);await process_frame
    check("Roster viewports bounded",preview.viewports.size()==5 and preview.get_child_count()==5)
    preview.update_preview(false,0,.1,false)
    var disabled:=true
    for vp in preview.viewports:disabled=disabled and vp.render_target_update_mode==SubViewport.UPDATE_DISABLED
    check("Hidden roster rendering disabled",disabled)
    var life:Node3D=s.backdrop.living
    var before:float=life.elapsed
    life.advance(.5,true,false)
    check("Background respects pause",life.elapsed==before)
    var start:float=life.moving_car.position.x
    life.advance(.5,false,false)
    check("Distant car moves",life.moving_car.position.x!=start)
    life.react();var cooldown:float=life.reaction_cooldown;life.react()
    check("Crowd reactions rate limited",cooldown==22 and life.reaction_cooldown==cooldown)
    check("Decoration count bounded",life.decoration_count<60 and life.actors.size()==4 and life.trees.size()==2,life.decoration_count)
    s.hud.close_page();s.audio.muted=true;s.hud._process(.1)
    check("Silent title recovery visible",s.hud.audio_restore.visible)
    s.hud._restore_sound();s.hud._process(.1)
    check("Recovery restores audible settings",not s.audio.silent_settings())
    s.hud.close_page();s.hud._process(.1);await shot("title")
    s.hud.open_page("settings");await shot("settings")
    s.hud.menu_scroll.scroll_vertical=2000;await shot("settings-sound")
    s.start_match(true)
    for i in 60:s._process(1.0/60)
    await shot("street")
    var report={"engine":Engine.get_version_info().string,"renderer":"Native Compatibility / llvmpipe","scope":"Native GPU screenshots and state assertions, not human play or FPS","checks":checks}
    var file:=FileAccess.open(OUT+"presentation-checks.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
    s.queue_free()
    for i in 4:await process_frame
    var failed:=false
    for row in checks:if not row.pass:failed=true
    quit(1 if failed else 0)
func shot(label:String) -> void:
    s.hud.queue_redraw()
    for i in 4:await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(OUT+label+".png")
