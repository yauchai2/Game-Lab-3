extends SceneTree
## Scrubs the boot story opening and saves real rendered frames.
## Usage: godot --path godot --script res://tools/capture_story_opening.gd -- [out_dir] [t1,t2,...]
var s:Node
func _initialize() -> void:call_deferred("run")
func run() -> void:
    var args:=OS.get_cmdline_user_args()
    var out:String=args[0] if args.size()>0 else "res://../docs/evidence/story-opening/"
    var times:Array=[]
    if args.size()>1:
        for part in args[1].split(","):times.append(float(part))
    else:times=[.4,1.5,2.7,3.5,4.5,5.5,6.55,7.3,8.02,8.6,9.4,10.6,12.4,13.05,13.6,14.7,15.3,15.85,16.03,16.2,17.4]
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.progression_path="/tmp/story-opening-capture/progression.cfg";root.add_child(s)
    s.audio.muted=true;s.reduced_effects=args.size()>2 and args[2]=="reduced";s.language=args[3] if args.size()>3 else "zh"
    await process_frame;await process_frame
    var op=s.story_opening
    op.scrub=true;op.begin()
    for t in times:
        op.sample(t)
        for i in 3:await process_frame
        var image:Image=root.get_texture().get_image()
        image.save_png(out.path_join("t%05.2f.png"%t))
        print("STORY_OPENING_FRAME ",t," shot ",op.shot," cam ",s.camera.global_position-op.ORIGIN," fov ",s.camera.fov)
    op.clear();s.screen="title"
    s.set_process(false);s.set_physics_process(false);s.audio.set_process(false);s.audio.music.stop();s.audio.fading_music.stop()
    await create_timer(.2).timeout;s.queue_free();s=null
    for i in 8:await process_frame
    quit()
