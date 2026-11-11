extends Node3D
## Live-world, reversible intermission. One local timeline owns all sound and lens.
const Timing=preload("res://scripts/combat/ability_draw/timing.gd")
const Tokens=preload("res://scripts/combat/ui/ui_theme.gd")
const Visuals=preload("res://scripts/combat/ability_draw/visuals.gd")
const Stage=preload("res://scripts/combat/ability_draw/stage_profile.gd")
var session:Node3D
var actors:Node3D
var stage:Resource
var entry_offset:=Vector3.ZERO
var state:="off"
var age:=0.0
var source_age:=0.0
var boundary:=""
var continuation:="round"
var result:Dictionary={}
var seed_value:=0
var saved:Dictionary={}
var saved_actors:Array=[]
var saved_shadows:Array=[]
var lens:ColorRect
var material:ShaderMaterial
var arrival:AudioStreamPlayer
var spin:AudioStreamPlayer
var reveal:AudioStreamPlayer
var accent:AudioStreamPlayer
var action:Button
var ui:CanvasLayer
var shown_count:=0
var rolled_count:=0
var restore_count:=0
var last_confirm_frame:=-1
var use_backup:=false
var compact_entry:=false
var last_skip:=false
var current_shot:=0
var input_armed:=false
var reveal_started:=false
const INK=Color("141024")
const CREAM=Color("f4e5c7")

func setup(owner_session:Node3D) -> void:
    session=owner_session;name="AbilityDraw"
    actors=Visuals.new();add_child(actors);actors.build();actors.hide()
    _toon(actors)
    var layer:=CanvasLayer.new();layer.layer=1;add_child(layer)
    lens=ColorRect.new();lens.mouse_filter=Control.MOUSE_FILTER_IGNORE;lens.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    material=ShaderMaterial.new();material.shader=preload("res://shaders/city_breaker_lens.gdshader");lens.material=material;layer.add_child(lens);lens.hide()
    arrival=_player("arrival");spin=_player("spin");reveal=_player("reveal");accent=_player("coin")
    ui=CanvasLayer.new();ui.layer=4;add_child(ui)
    action=Button.new();action.name="AbilityDrawAction";action.theme=Tokens.build()
    action.add_theme_font_override("font",Tokens.DISPLAY)
    action.add_theme_font_size_override("font_size",floori(Tokens.ACTION_SIZE/2.0))
    for kind in ["normal","hover","pressed","disabled"]:
        var color:Color=Tokens.PAPER if kind=="normal" else (Tokens.TEAL if kind=="pressed" else (Tokens.MUTED if kind=="disabled" else Tokens.MAGENTA))
        var style:=Tokens.plate(color,Tokens.INK,2);style.set_content_margin_all(4)
        style.shadow_color=Tokens.INK;style.shadow_size=3;style.shadow_offset=Vector2(3,3)
        action.add_theme_stylebox_override(kind,style)
        action.add_theme_color_override("font_"+kind+"_color",Tokens.INK)
    action.add_theme_color_override("font_color",Tokens.INK)
    ui.add_child(action);action.pressed.connect(confirm);action.hide()

func _toon(node:Node) -> void:
    if node is MeshInstance3D and node.material_override is StandardMaterial3D:
        var base:StandardMaterial3D=node.material_override
        if base.albedo_texture==null and base.shading_mode!=BaseMaterial3D.SHADING_MODE_UNSHADED:
            var m:=ShaderMaterial.new();m.shader=preload("res://shaders/ability_draw_toon.gdshader");m.set_shader_parameter("base_color",base.albedo_color);node.material_override=m
    for child in node.get_children():_toon(child)

func _player(id:String) -> AudioStreamPlayer:
    var p:=AudioStreamPlayer.new();p.stream=load("res://audio/ability_draw/"+("rhythm/" if id in ["arrival","spin","reveal"] else "")+id+".wav");p.bus="Afterhours SFX";add_child(p);return p

func active() -> bool:return state!="off"

func begin(id:String,next_kind:String,random_seed:int,profile:Resource=null) -> void:
    clear()
    session.round_theatre.clear();session.city_breaker.clear();session.neon.clear();session.theatre.clear();session.rhythm.clear();session.spectacle.clear()
    boundary=id;continuation=next_kind;seed_value=random_seed
    stage=profile if profile!=null else Stage.new()
    transform=stage.world_transform()
    var space:=get_world_3d().direct_space_state
    use_backup=not stage.lane_clear(space,stage.entry_offset)
    entry_offset=stage.backup_entry_offset if use_backup else stage.entry_offset
    # A blocked compact stage still receives an animated graphic reveal; never
    # expose a newly spawned stationary cast in the first frame.
    compact_entry=use_backup and not stage.lane_clear(space,entry_offset)
    if compact_entry:entry_offset=Vector3.ZERO
    saved={"transform":session.camera.transform,"fov":session.camera.fov,"near":session.camera.near,"far":session.camera.far,"environment":session.camera.environment,"duck":session.audio.cinematic_duck,"backdrop":session.backdrop.visible,"living":session.backdrop.living.visible}
    saved_actors.clear();saved_shadows.clear()
    for actor in session.fighters:saved_actors.append({"node":actor,"visible":actor.visible});actor.hide()
    for shadow in session.silhouettes:saved_shadows.append({"node":shadow,"visible":shadow.visible});shadow.hide()
    session.backdrop.living.hide()
    for puff in actors.dust:
        (puff.material_override as ShaderMaterial).set_shader_parameter("base_color",stage.dust_color)
    actors.show();state="arrival";age=0;source_age=0;input_armed=false;reveal_started=false;result={};last_skip=false;shown_count+=1
    session.pending.clear();session.finish_menu_open=false
    arrival.play();_sync_audio(false);sample()
    session.hud.rebuild_menu()

func advance(delta:float,paused:bool) -> void:
    if not active():return
    _sync_audio(paused)
    action.visible=not paused and state in ["offer","result"]
    if paused:sample();return
    age+=maxf(0,delta)
    if state=="arrival":
        source_age=Timing.arrival(age)
        if age>=Timing.ARRIVAL_DURATION:_wait("offer")
    elif state=="offer":source_age=2.16
    elif state=="spin":
        source_age=Timing.spin(age)
        if age>=1.48 and spin.playing:spin.stop()
        if age>=Timing.REVEAL_AT and not reveal_started:
            reveal_started=true;reveal.play(maxf(0,age-Timing.REVEAL_AT))
        if age>=Timing.SPIN_DURATION:_wait("result")
    elif state=="result":source_age=4.1
    if state in ["offer","result"] and age>=Timing.INPUT_SETTLE and not _accept_held():input_armed=true
    action.disabled=not input_armed
    sample()

func _wait(next_state:String) -> void:
    state=next_state;age=0;input_armed=false
    source_age=2.16 if next_state=="offer" else 4.1

func _accept_held() -> bool:
    return Input.is_action_pressed("ui_accept") or Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER) or Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

func handle_key(event:InputEventKey) -> void:
    if event.is_echo():return
    if state=="arrival":skip()
    elif state=="spin":
        if event.keycode==KEY_SPACE and age>=.25:skip()
    else:confirm()

func confirm() -> void:
    if not active() or session.screen!="result":return
    # GUI callbacks and key handlers cannot consume a single press twice.
    var frame:=Engine.get_process_frames()
    if frame==last_confirm_frame:return
    last_confirm_frame=frame
    if state=="arrival":skip();return
    if state in ["offer","result"] and not input_armed:return
    if state=="offer":
        input_armed=false;reveal_started=false
        result=session.draw_rewards.roll(boundary,seed_value);rolled_count+=1
        state="spin";age=0;source_age=2.55;_accent("coin");spin.play();action.hide()
    elif state=="result":
        var item:=result.duplicate();var next_kind:=continuation
        clear();session.complete_ability_draw(item,next_kind)

func skip() -> void:
    last_skip=true
    if state=="arrival":_wait("offer");arrival.stop()
    elif state=="spin":_wait("result");spin.stop();reveal.stop();_accent("confirm")
    sample()

func _accent(id:String) -> void:
    accent.stop();accent.stream=load("res://audio/ability_draw/"+id+".wav");accent.play()

func _sync_audio(paused:bool) -> void:
    for p in [arrival,spin,reveal,accent]:
        p.stream_paused=paused
        p.volume_db=-80.0 if session.audio.muted or session.audio.effects_level<=0 else -9.0+linear_to_db(maxf(.001,session.audio.effects_level))
    session.audio.cinematic_duck=.18 if state in ["offer","result"] else (.80 if state=="spin" and age>=1.48 and age<Timing.REVEAL_AT else .55)

func sample() -> void:
    if not active():return
    for a in saved_actors:if is_instance_valid(a.node):a.node.hide()
    for a in saved_shadows:if is_instance_valid(a.node):a.node.hide()
    session.arena_cage.hide();session.backdrop.visible=true;session.grade.hide()
    session.camera.environment=null;session.camera.near=.04
    var t:=source_age
    var progress:=smoothstep(.16,1.06,t)
    var offset:Vector3=entry_offset*(1-progress)
    var spin_amount:float=age if state=="spin" else -1.0
    var burst:=clampf((t-3.5)/.50,0,1) if state in ["spin","result"] else 0.0
    var id:String=result.get("id","speed")
    actors.pose(t,offset,spin_amount,id,burst,session.reduced_effects)
    actors.reward_backdrop.visible=state=="result"
    var camera_at:=Vector3(-1.7,.32,3.5)
    var target:=Vector3(-.25,1.18,0)
    if state=="arrival" and t<1.25:
        # Begin looking into clear stage space. The cast is physically outside
        # this frame, then travels in as the camera pans back to the landing.
        target.x=lerpf(-signf(entry_offset.x)*1.7,-.25,smoothstep(.28,1.05,t))
    var fov:=52.0;var roll:=0.0;var distortion:=0.0;var punch:=0.0
    current_shot=0
    if t>=1.25 and t<1.95:
        current_shot=1;camera_at=Vector3(-.10,2.85,1.5);target=Vector3(.10,2.25,.05);fov=78.0;roll=-.10;distortion=.26
        punch=maxf(0,1-absf(t-1.42)/.16)
    elif state=="offer":
        current_shot=2;camera_at=Vector3(-1.27,2.40,2.45);target=Vector3(-.91,2.16,.22);fov=73.0;roll=-.075;distortion=.23
    elif state=="spin" and t<3.5:
        current_shot=3;camera_at=Vector3(.03,1.72,.95);target=Vector3(.01,1.72,-.25);fov=52.0;roll=sin(age*22)*.025;distortion=.14
    elif state=="spin":
        current_shot=4;camera_at=Vector3(-1.4,.70,3.1);target=Vector3(-.15,1.9,.3);fov=90;roll=-.14;distortion=.45;punch=maxf(0,1-absf(t-3.56)/.18)
    elif state=="result":
        current_shot=5
        # Foreground hero object stays true 3D. Graphic frame masks the city only
        # behind it, so no captured video or generated fake 3D is used.
        camera_at=Vector3(-.15,1.9,4.3);target=Vector3(-.10,1.8,.45);fov=48
        actors.reward.position=Vector3(-.72,1.87,1.22);actors.reward.rotation=Vector3(.10,-.12,-.28)
        actors.reward.scale=Vector3.ONE*1.8
        actors.dealer.hide();actors.machine.hide()
    if state!="result":actors.reward.scale=Vector3.ONE;actors.dealer.show();actors.machine.show()
    if compact_entry and state=="arrival" and t<.28:
        actors.dealer.hide();actors.machine.hide()
    if session.reduced_effects:distortion=0;roll=0;punch=0
    var shake:=Vector3(sin(t*97),cos(t*131),sin(t*53))*punch*.055
    session.camera.global_position=to_global(camera_at+shake)
    session.camera.look_at(to_global(target),Vector3.UP);session.camera.rotation.z+=roll
    session.camera.fov=fov
    material.set_shader_parameter("fisheye",distortion)
    material.set_shader_parameter("blur",0.0 if session.reduced_effects or state=="result" else punch*.15+(.035 if state=="spin" and t<3.25 else 0.0))
    material.set_shader_parameter("impact",punch*.7)
    material.set_shader_parameter("ring_phase",clampf((t-3.5)*3,0,1))
    lens.visible=not session.reduced_effects and state!="result"
    action.text="DRAW" if state=="offer" else "CONTINUE"
    var extent:=session.get_viewport().get_visible_rect().size
    var rect:=Rect2(920,568,312,72) if state=="offer" else Rect2(720,560,480,72)
    action.position=rect.position*extent/Vector2(1280,720);action.size=rect.size*extent/Vector2(1280,720)

func draw(canvas:Control) -> void:
    if not active() or session.screen!="result":return
    var bold:Font=session.hud.bold;var font:Font=session.hud.font
    if state=="result":
        canvas.draw_rect(Rect2(650,120,570,420),Tokens.NIGHT)
        var color:Color=result.get("color",Tokens.TEAL)
        canvas.draw_rect(Rect2(680,154,8,330),color)
        canvas.draw_string(font,Vector2(720,185),"NEXT ROUND",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Tokens.MUTED)
        canvas.draw_string(bold,Vector2(720,264),result.get("title","CORE"),HORIZONTAL_ALIGNMENT_LEFT,-1,48,Tokens.PAPER)
        var row:=0
        for stat in str(result.get("detail","")).split(" / "):
            var split:int=stat.rfind(" ")
            canvas.draw_string(font,Vector2(720,346+row*64),stat.substr(0,split),HORIZONTAL_ALIGNMENT_LEFT,-1,28,Tokens.MUTED)
            canvas.draw_string(bold,Vector2(1080,346+row*64),stat.substr(split+1),HORIZONTAL_ALIGNMENT_RIGHT,120,32,color)
            row+=1
    else:
        canvas.draw_rect(Rect2(24,24,280,48),Tokens.NIGHT)
        canvas.draw_rect(Rect2(24,24,6,48),Tokens.MAGENTA)
        canvas.draw_string(bold,Vector2(46,58),"THE DEALER",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Tokens.PAPER)
        var peak:=maxf(maxf(0,1-absf(source_age-1.06)/.11),maxf(0,1-absf(source_age-1.42)/.12))
        if state=="spin":peak=maxf(peak,maxf(0,1-absf(source_age-3.56)/.20))
        if not session.reduced_effects and peak>0:
            for i in 17:
                var a:=TAU*i/17+.11;var ray:=Vector2(cos(a),sin(a));var p:=Vector2(640,350)+ray*260
                canvas.draw_colored_polygon(PackedVector2Array([p,Vector2(640,350)+ray*900+ray.orthogonal()*22,Vector2(640,350)+ray*900-ray.orthogonal()*22]),Color(1,.8,.18,peak))
            canvas.draw_string(bold,Vector2(850,220),"WHAM!" if source_age<2 else "JACKPOT!",HORIZONTAL_ALIGNMENT_LEFT,-1,68,CREAM)
    if compact_entry and state=="arrival" and source_age<.68:
        var wipe:=smoothstep(.28,.68,source_age)
        var edge:=lerpf(1600.0,-360.0,wipe)
        canvas.draw_colored_polygon(PackedVector2Array([Vector2(-400,0),Vector2(edge,0),Vector2(edge-260,720),Vector2(-400,720)]),Color("4f1b80"))
        canvas.draw_line(Vector2(edge-20,0),Vector2(edge-280,720),Color("ed7827"),32)
    if state in ["offer","result"]:
        var x:=920.0 if state=="offer" else 720.0
        canvas.draw_string(font,Vector2(x,670),"ENTER / SPACE",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Tokens.MUTED)
    elif state=="spin":
        canvas.draw_string(font,Vector2(28,690),"SPACE  SKIP",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Tokens.MUTED)

func clear() -> void:
    var was_active:=active()
    state="off";age=0
    if is_instance_valid(actors):actors.hide()
    if is_instance_valid(action):action.hide()
    if is_instance_valid(lens):lens.hide();material.set_shader_parameter("fisheye",0.0);material.set_shader_parameter("blur",0.0);material.set_shader_parameter("impact",0.0)
    for p in [arrival,spin,reveal,accent]:
        if is_instance_valid(p):
            p.stream_paused=false
            if p.has_stream_playback():p.get_stream_playback().stop()
            p.stop()
    if not was_active:return
    restore_count+=1
    if is_instance_valid(session.camera) and not saved.is_empty():
        session.camera.transform=saved.transform;session.camera.fov=saved.fov;session.camera.near=saved.near;session.camera.far=saved.far;session.camera.environment=saved.environment
        session.audio.cinematic_duck=saved.duck;session.backdrop.visible=saved.backdrop;session.backdrop.living.visible=saved.living
    for a in saved_actors:if is_instance_valid(a.node):a.node.visible=a.visible
    for a in saved_shadows:if is_instance_valid(a.node):a.node.visible=a.visible
    saved.clear();saved_actors.clear();saved_shadows.clear()
    session.pending.clear()


func _exit_tree() -> void:
    clear()
    for p in [arrival,spin,reveal,accent]:
        if is_instance_valid(p):p.stream=null
