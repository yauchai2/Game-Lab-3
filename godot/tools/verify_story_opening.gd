extends SceneTree
## Native checks for the boot story opening: ownership, timeline, input, save flag, restore.
const OUT="res://../docs/evidence/story-opening/"
const SAVE_DIR="/tmp/story-opening-verify"
var s:Node
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("STORY_OPENING ",label," ",ok)
    if not ok:push_error(label)
func step(n:int=1) -> void:
    for i in n:s._physics_process(1.0/60);s._process(1.0/60)
func smp(authored_time:float) -> void:s.story_opening.sample(s.story_opening.real_time(authored_time))
func key(code:int) -> void:
    var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=true;s._unhandled_key_input(event)
func make() -> Node:
    var node:Node=preload("res://scenes/combat/street_fight.tscn").instantiate();node.preferences_path="";node.progression_path=SAVE_DIR+"/progression.cfg"
    root.add_child(node);node.set_process(false);node.set_physics_process(false);node.audio.muted=true;node.reduced_effects=false
    return node
func run() -> void:
    for file in ["story_opening.cfg","progression.cfg"]:
        if FileAccess.file_exists(SAVE_DIR+"/"+file):DirAccess.remove_absolute(SAVE_DIR+"/"+file)
    s=make()
    await process_frame;await process_frame
    var op=s.story_opening
    check("tools that instantiate the scene stay on the menu",s.screen=="title" and not op.active() and not s.story_opening_wanted())
    check("a fresh save has not seen the opening",not op.seen)
    check("timeline follows the reference video: ends on the lid slam, nine shots",op.DURATION==16.12 and op.AUTHORED_END==13.12 and absf(op.real_time(op.authored(7.3))-7.3)<.001 and absf(op.authored(op.DURATION)-op.AUTHORED_END)<.001 and op.CUTS==[0.0,1.3,2.6,4.5,5.0,6.75,9.0,12.0,13.0,13.12] and op.SHOTS.size()==9)
    var camera:Camera3D=s.camera
    # The session re-drives its title camera each frame, so framing is compared with a tolerance.
    var before:={"transform":camera.transform,"fov":camera.fov,"near":camera.near,"far":camera.far,"environment":camera.environment}
    var backdrop_visible:bool=s.backdrop.visible
    op.begin()
    check("begin owns the frame",op.active() and s.screen=="opening" and not s.backdrop.visible and camera.environment==op.environment and op.lens.visible)
    check("the old bike, speaker, wrench and black car are gone from the set",op.stage.get("bike")==null and op.stage.get("speaker_cone")==null and op.stage.get("wrench")==null and op.stage.get("car")==null)
    check("menu and art buttons are hidden during the opening",not s.hud.menu.visible and not s.hud.art_controls.visible)
    check("cast is the four roster models plus three collectors",op.cast.size()==4 and op.suits.size()==3 and op.cast[0].visual.character_index==0 and op.cast[1].visual.character_index==1 and op.cast[2].visual.character_index==2 and op.cast[3].visual.character_index==3 and op.suits[0].visual.character_index==4)
    var shots:Array=[]
    for t in [.6,1.9,3.5,4.7,5.8,8.0,10.5,12.3,14.0]:smp(t);shots.append(op.shot)
    check("each moment maps to its shot",shots==[0,1,2,3,4,5,6,7,8])
    smp(7.2);var first:Transform3D=camera.global_transform;var hand:Vector3=op.cast[0].point("RightHand")
    smp(10.6);smp(7.2)
    check("sampling is stateless and repeatable",first.is_equal_approx(camera.global_transform) and hand.is_equal_approx(op.cast[0].point("RightHand")))
    smp(.5);check("the bench starts empty with ZIP behind it",op.cast[0].visible and not op.stage.case_root.visible and op.cast[0].global_position.z>op.Stage.TABLE.z)
    smp(1.0);check("the case slides in from the left along the bench",op.stage.case_root.visible and op.stage.case_root.position.x>op.Stage.TABLE.x+.1 and op.stage.case_lid.rotation.x==0)
    smp(2.0);check("RIVET works the latches; HUSH, LOOP and the collectors are not in shot",op.cast[1].visible and not op.cast[2].visible and not op.cast[3].visible and not op.suits[0].visible)
    smp(1.32);check("case lands closed on the bench with a camera jolt",op.stage.case_root.position.distance_to(op.Stage.TABLE)<.06 and op.stage.case_lid.rotation.x==0 and op.shake>.05)
    smp(2.4);check("both latches are thrown",op.stage.case_latches[0].rotation.x<-1.0 and op.stage.case_latches[1].rotation.x<-1.0)
    smp(3.5);check("overhead reveal shows the open case with LOOP at the manifest",op.stage.case_lid.rotation.x>1.5 and op.cast[3].visible and not op.cast[1].visible)
    smp(4.7);check("ZIP's face is framed close with the collectors already walking",op.cast[0].visible and op.suits[0].visible and op.cast[0].point("Head").distance_to(camera.global_position)<1.6)
    smp(5.3);check("three collectors walk in step",op.suits[0].visible and op.suits[1].visible and op.suits[2].visible and op.suits[0].visual.motions.clip_elapsed==op.suits[1].visual.motions.clip_elapsed and op.suits[1].visual.motions.clip_elapsed==op.suits[2].visual.motions.clip_elapsed and op.suits[0].visual.motions.clip_name=="Walk_Loop")
    smp(8.0);check("the cut to the case turns it so the lid stands clear",op.stage.case_root.rotation.y<-1.4 and op.stage.case_lid.rotation.x>1.5 and op.cast[0].visible and not op.cast[3].visible)
    smp(10.7);check("the collectors step forward on the shoe beats",op.suits[0].global_position.z<op.SUIT_MARKS[0].z+op.ORIGIN.z-.4)
    smp(12.6);var lid_open:float=op.stage.case_lid.rotation.x;smp(13.0);check("lid is driven shut for the slam frame",lid_open>1.5 and op.stage.case_lid.rotation.x<.01 and op.stage.case_print.visible)
    smp(13.04);check("slam holds a black impact frame",op.material.get_shader_parameter("fade")==1.0 and not op.logo.visible)
    smp(13.6);check("title shows wordmark, ink city and flat silhouettes",op.logo.visible and op.material.get_shader_parameter("ink")==1.0 and op.cast[0].visual.materials[0].get_shader_parameter("neon_silhouette")==1.0)
    smp(5.0);check("silhouettes are released outside the title",op.cast[0].visual.materials[0].get_shader_parameter("neon_silhouette")==0.0 and op.material.get_shader_parameter("ink")==0.0)
    smp(5.02);var lively:bool=op.material.get_shader_parameter("fisheye")>0 and op.shake>0
    s.reduced_effects=true;smp(5.02)
    check("reduced effects removes fisheye, blur, flash and shake",lively and op.material.get_shader_parameter("fisheye")==0.0 and op.material.get_shader_parameter("blur")==0.0 and op.material.get_shader_parameter("flash")==0.0 and op.shake==0.0)
    s.reduced_effects=false
    # Real clock, input and audio ducking.
    op.begin();step(30)
    check("the clock advances with the game frame",op.age>.45 and op.age<.55)
    key(KEY_T);key(KEY_F12);key(KEY_C);key(KEY_J)
    check("other keys cannot start a mode during the opening",s.screen=="opening" and op.active() and s.pending.is_empty() and s.demo==null)
    key(KEY_ESCAPE);var held:float=op.age;step(40)
    check("Esc pauses clock and score",op.paused and op.age==held and op.score.stream_paused)
    key(KEY_ESCAPE);step(6);check("Esc resumes",not op.paused and op.age>held)
    op.age=4.0;step(2)
    check("menu music stays silent under the baked score, never stopped",s.audio.cinematic_duck>=10.0 and s.audio.music_gain_db<=-79.0 and s.audio.music.playing)
    op.age=10.0;step(2)
    check("menu music is still silent for the stand-off",s.audio.cinematic_duck>=10.0 and s.audio.music.playing)
    op.age=16.1;step(1)
    check("menu music fades back in after the title hit",s.audio.cinematic_duck==0.0 and (s.audio.music_gain_db>-60.0 or s.audio.muted or s.audio.music_muted))
    op.age=16.11;step(6)
    check("the opening ends by itself on the main menu",not op.active() and s.screen=="title" and op.finished_count==1)
    check("camera, lens and street are restored",camera.position.distance_to(before.transform.origin)<2.0 and camera.basis.z.dot(before.transform.basis.z)>.99 and camera.fov==before.fov and camera.near==before.near and camera.far==before.far and camera.environment==before.environment and s.backdrop.visible==backdrop_visible and not op.lens.visible and not op.logo.visible and not op.stage.visible)
    await process_frame
    check("main menu buttons are back and usable",s.hud.art_controls.visible and s.hud.art_buttons.has("fight") and s.hud.art_buttons.fight.is_visible_in_tree())
    check("seen flag is saved beside progression",op.seen and FileAccess.file_exists(SAVE_DIR+"/story_opening.cfg"))
    # Replay from FREE PLAY and skip; settings must not repeat the entry.
    s.hud.open_page("settings");step(4)
    var in_settings:=false
    for node in s.hud.menu_stack.get_children():
        if node is Button and node.get_meta("ui_key","")=="replay_opening":in_settings=true
    s.hud.close_page();s.hud.open_page("free_play");step(4)
    var watch:Button=null
    for node in s.hud.menu_stack.get_children():
        if node is Button and node.get_meta("ui_key","")=="replay_opening":watch=node
    check("FREE PLAY has WATCH OPENING and settings no longer repeats it",watch!=null and watch.text=="WATCH OPENING" and not in_settings)
    var cam_pre:Transform3D=camera.transform
    watch.pressed.emit();step(20)
    check("replay starts from the title",op.active() and op.replay and s.screen=="opening")
    key(KEY_SPACE)
    check("after the replay the main menu is back",s.hud.menu_page=="main" and s.screen=="title")

    check("Space skips straight to the menu and restores the camera",not op.active() and s.screen=="title" and camera.position.distance_to(cam_pre.origin)<1.0 and camera.fov==before.fov and camera.environment==before.environment and s.audio.cinematic_duck==0.0)
    s.start_match(false)
    check("a match starts normally afterwards",s.screen=="play" and s.fighters[0].visible and s.backdrop.visible)
    s.return_to_title();s.replay_story_opening();step(10);s._exit_tree()
    check("leaving the scene mid-opening clears it",not op.active() and not op.lens.visible)
    s.set_process(false);s.audio.set_process(false);s.audio.music.stop();s.audio.fading_music.stop()
    s.queue_free();s=null
    for i in 6:await process_frame
    s=make();await process_frame
    check("the next launch remembers it was seen",s.story_opening.seen and not s.story_opening_wanted())
    s.story_opening_every_boot=true
    check("without being the running game it still never autoplays",not s.story_opening_wanted())
    var passed:=0
    for item in checks:
        if item.passed:passed+=1
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"suite":"story_opening","passed":passed,"total":checks.size(),"checks":checks},"  ")+"\n")
    print("STORY_OPENING_RESULT ",passed,"/",checks.size())
    s.set_process(false);s.set_physics_process(false);s.audio.set_process(false);s.audio.music.stop();s.audio.fading_music.stop()
    await create_timer(.2).timeout;s.queue_free();s=null
    for i in 8:await process_frame
    quit(0 if passed==checks.size() else 1)
