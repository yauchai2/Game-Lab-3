extends Node3D
## Live-world, reversible intermission. One local timeline owns all sound and lens.
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
var last_skip:=false
var current_shot:=0
var auto_age:=0.0
const INK=Color("141024")
const CREAM=Color("f4e5c7")
const CYAN=Color("44ffdd")

func setup(owner_session:Node3D) -> void:
    session=owner_session;name="AbilityDraw"
    actors=Visuals.new();add_child(actors);actors.build();actors.hide()
    _toon(actors)
    var layer:=CanvasLayer.new();layer.layer=1;add_child(layer)
    lens=ColorRect.new();lens.mouse_filter=Control.MOUSE_FILTER_IGNORE;lens.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    material=ShaderMaterial.new();material.shader=preload("res://shaders/city_breaker_lens.gdshader");lens.material=material;layer.add_child(lens);lens.hide()
    arrival=_player("arrival");spin=_player("spin");reveal=_player("reveal");accent=_player("coin")
    ui=CanvasLayer.new();ui.layer=4;add_child(ui)
    action=Button.new();action.name="AbilityDrawAction";action.text="SPIN / FREE";action.add_theme_font_size_override("font_size",16)
    action.add_theme_color_override("font_color",INK)
    var style:=StyleBoxFlat.new();style.bg_color=CYAN;style.border_color=INK;style.set_border_width_all(3);style.set_content_margin_all(6)
    action.add_theme_stylebox_override("normal",style);var hover:=style.duplicate();hover.bg_color=CREAM;action.add_theme_stylebox_override("hover",hover);action.add_theme_stylebox_override("focus",hover)
    ui.add_child(action);action.pressed.connect(confirm);action.hide()

func _toon(node:Node) -> void:
    if node is MeshInstance3D and node.material_override is StandardMaterial3D:
        var base:StandardMaterial3D=node.material_override
        if base.albedo_texture==null and base.shading_mode!=BaseMaterial3D.SHADING_MODE_UNSHADED:
            var m:=ShaderMaterial.new();m.shader=preload("res://shaders/ability_draw_toon.gdshader");m.set_shader_parameter("base_color",base.albedo_color);node.material_override=m
    for child in node.get_children():_toon(child)

func _player(id:String) -> AudioStreamPlayer:
    var p:=AudioStreamPlayer.new();p.stream=load("res://audio/ability_draw/"+id+".ogg");p.bus="Afterhours SFX";add_child(p);return p

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
    # If both authored lanes are obstructed, enter through a brief smoke wipe at
    # the clear landing point; never sweep through obstructing scene geometry.
    if use_backup and not stage.lane_clear(space,entry_offset):entry_offset=Vector3.ZERO
    saved={"transform":session.camera.transform,"fov":session.camera.fov,"near":session.camera.near,"far":session.camera.far,"environment":session.camera.environment,"duck":session.audio.cinematic_duck,"backdrop":session.backdrop.visible,"living":session.backdrop.living.visible}
    saved_actors.clear();saved_shadows.clear()
    for actor in session.fighters:saved_actors.append({"node":actor,"visible":actor.visible});actor.hide()
    for shadow in session.silhouettes:saved_shadows.append({"node":shadow,"visible":shadow.visible});shadow.hide()
    session.backdrop.living.hide()
    for puff in actors.dust:
        (puff.material_override as ShaderMaterial).set_shader_parameter("base_color",stage.dust_color)
    actors.show();state="arrival";age=0;source_age=0;auto_age=0;result={};last_skip=false;shown_count+=1
    session.pending.clear();session.finish_menu_open=false
    arrival.play();_sync_audio(false);sample()
    session.hud.rebuild_menu()

func advance(delta:float,paused:bool) -> void:
    if not active():return
    _sync_audio(paused)
    action.visible=not paused and state in ["offer","result"] and session.demo==null
    if paused:sample();return
    age+=maxf(0,delta)
    auto_age+=maxf(0,delta)
    if state=="arrival":
        source_age=minf(1.95,age)
        if age>=1.95:
            state="offer";age=0;source_age=2.16
    elif state=="offer":
        source_age=2.16
        if session.demo!=null and age>=.45:confirm()
    elif state=="spin":
        source_age=2.55+minf(age,1.45)
        if age>=.68 and spin.playing:spin.stop();reveal.play()
        if age>=1.45:state="result";age=0;source_age=4.1;_accent("confirm")
    elif state=="result":
        source_age=4.1
        if session.demo!=null and age>=1.0:confirm()
    sample()

func confirm() -> void:
    if not active() or session.screen!="result":return
    # GUI callbacks and key handlers cannot consume a single press twice.
    var frame:=Engine.get_process_frames()
    if frame==last_confirm_frame:return
    last_confirm_frame=frame
    if state=="arrival":skip();return
    if state=="offer":
        result=session.draw_rewards.roll(boundary,seed_value);rolled_count+=1
        state="spin";age=0;source_age=2.55;_accent("coin");spin.play();action.hide()
    elif state=="spin":skip()
    elif state=="result":
        var item:=result.duplicate();var next_kind:=continuation
        clear();session.complete_ability_draw(item,next_kind)

func skip() -> void:
    last_skip=true
    if state=="arrival":state="offer";age=0;source_age=2.16;arrival.stop()
    elif state=="spin":state="result";age=0;source_age=4.1;spin.stop();reveal.stop();_accent("confirm")
    sample()

func _accent(id:String) -> void:
    accent.stop();accent.stream=load("res://audio/ability_draw/"+id+".ogg");accent.play()

func _sync_audio(paused:bool) -> void:
    for p in [arrival,spin,reveal,accent]:
        p.stream_paused=paused
        p.volume_db=-80 if session.audio.muted or session.audio.effects_level<=0 else -9+linear_to_db(maxf(.001,session.audio.effects_level))
    session.audio.cinematic_duck=.60

func sample() -> void:
    if not active():return
    for a in saved_actors:if is_instance_valid(a.node):a.node.hide()
    for a in saved_shadows:if is_instance_valid(a.node):a.node.hide()
    session.arena_cage.hide();session.backdrop.visible=true;session.grade.hide()
    session.camera.environment=null;session.camera.near=.04
    var t:=source_age
    var progress:=clampf(t/.78,0,1)
    var offset:Vector3=entry_offset*pow(1-progress,2)
    var spin_amount:float=age if state=="spin" else -1.0
    var burst:=clampf((t-3.5)/.50,0,1) if state in ["spin","result"] else 0.0
    var id:String=result.get("id","speed")
    actors.pose(t,offset,spin_amount,id,burst,session.reduced_effects)
    actors.reward_backdrop.visible=state=="result"
    var camera_at:=Vector3(-1.7,.32,3.5)
    var target:=Vector3(-.25,1.18,0)
    var fov:=52.0;var roll:=0.0;var distortion:=0.0;var punch:=0.0
    current_shot=0
    if t>=1.25 and t<1.95:
        current_shot=1;camera_at=Vector3(-.10,2.85,1.5);target=Vector3(.10,2.25,.05);fov=78.0;roll=-.10;distortion=.26
        punch=maxf(0,1-absf(t-1.42)/.16)
    elif state=="offer":
        current_shot=2;camera_at=Vector3(-1.27,2.40,2.45);target=Vector3(-.91,2.16,.22);fov=73.0;roll=-.075;distortion=.23
    elif state=="spin" and t<3.5:
        current_shot=3;camera_at=Vector3(.12,1.71,1.78);target=Vector3(0,1.72,.20);fov=68.0;roll=sin(age*22)*.025;distortion=.14
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
    if session.reduced_effects:distortion=0;roll=0;punch=0
    var shake:=Vector3(sin(t*97),cos(t*131),sin(t*53))*punch*.055
    session.camera.global_position=to_global(camera_at+shake)
    session.camera.look_at(to_global(target),Vector3.UP);session.camera.rotation.z+=roll
    session.camera.fov=fov
    material.set_shader_parameter("fisheye",distortion)
    material.set_shader_parameter("blur",0.0 if session.reduced_effects or state=="result" else punch*.15+(.035 if state=="spin" and t<3.25 else 0))
    material.set_shader_parameter("impact",punch*.7)
    material.set_shader_parameter("ring_phase",clampf((t-3.5)*3,0,1))
    lens.visible=not session.reduced_effects and state!="result"
    action.text="SPIN / FREE" if state=="offer" else "TAKE CORE / CONTINUE"
    var extent:=session.get_viewport().get_visible_rect().size
    action.position=extent*Vector2(.58,.78);action.size=extent*Vector2(.36,.11)

func draw(canvas:Control) -> void:
    if not active() or session.screen!="result":return
    var bold:Font=session.hud.bold;var font:Font=session.hud.font
    if state=="result":
        # Keep the 3D capsule silhouette visible in the left-side cutout.
        canvas.draw_colored_polygon(PackedVector2Array([Vector2(0,0),Vector2(1280,0),Vector2(1280,720),Vector2(0,720),Vector2(0,510),Vector2(200,650),Vector2(590,560),Vector2(570,130),Vector2(180,90),Vector2(0,210)]),Color("4f1b80"))
        for i in 11:
            var y:=float(i)*85-70
            canvas.draw_colored_polygon(PackedVector2Array([Vector2(590,y+90),Vector2(1280,y),Vector2(1280,y+24),Vector2(620,y+110)]),Color("ed7827"))
        canvas.draw_rect(Rect2(620,180,640,310),INK)
        canvas.draw_string(bold,Vector2(650,265),result.get("title","CORE"),HORIZONTAL_ALIGNMENT_LEFT,-1,66,CREAM)
        canvas.draw_string(font,Vector2(650,330),result.get("detail",""),HORIZONTAL_ALIGNMENT_LEFT,-1,28,CYAN)
        canvas.draw_string(bold,Vector2(650,407),"NEXT ROUND ONLY",HORIZONTAL_ALIGNMENT_LEFT,-1,36,Color("ffca42"))
        canvas.draw_string(font,Vector2(650,457),"NO XP COST / ONE DRAW",HORIZONTAL_ALIGNMENT_LEFT,-1,24,CREAM)
    else:
        canvas.draw_rect(Rect2(0,0,1280,40),INK)
        canvas.draw_string(bold,Vector2(28,31),"THE DEALER / BETWEEN ROUNDS",HORIZONTAL_ALIGNMENT_LEFT,-1,26,CREAM)
        if state=="offer":
            canvas.draw_rect(Rect2(705,420,550,120),INK)
            canvas.draw_string(bold,Vector2(730,465),"ONE TOKEN. ONE CHANCE.",HORIZONTAL_ALIGNMENT_LEFT,-1,32,Color("ffca42"))
            canvas.draw_string(font,Vector2(730,508),"A RANDOM CORE FOR THE NEXT FIGHT",HORIZONTAL_ALIGNMENT_LEFT,-1,24,CREAM)
        var peak:=maxf(maxf(0,1-absf(source_age-.56)/.11),maxf(0,1-absf(source_age-1.42)/.12))
        if state=="spin":peak=maxf(peak,maxf(0,1-absf(source_age-3.56)/.20))
        if not session.reduced_effects and peak>0:
            for i in 17:
                var a:=TAU*i/17+.11;var ray:=Vector2(cos(a),sin(a));var p:=Vector2(640,350)+ray*260
                canvas.draw_colored_polygon(PackedVector2Array([p,Vector2(640,350)+ray*900+ray.orthogonal()*22,Vector2(640,350)+ray*900-ray.orthogonal()*22]),Color(1,.8,.18,peak))
            canvas.draw_string(bold,Vector2(850,220),"WHAM!" if source_age<2 else "JACKPOT!",HORIZONTAL_ALIGNMENT_LEFT,-1,68,CREAM)
    canvas.draw_rect(Rect2(0,684,1280,36),INK)
    canvas.draw_string(font,Vector2(24,711),"ENTER / SPACE  "+("SPIN" if state=="offer" else ("TAKE CORE" if state=="result" else "SKIP"))+"     ESC  PAUSE     F2  REDUCE FX",HORIZONTAL_ALIGNMENT_LEFT,-1,24,CREAM)

func clear() -> void:
    var was_active:=active()
    state="off";age=0
    if is_instance_valid(actors):actors.hide()
    if is_instance_valid(action):action.hide()
    if is_instance_valid(lens):lens.hide();material.set_shader_parameter("fisheye",0.0);material.set_shader_parameter("blur",0.0);material.set_shader_parameter("impact",0.0)
    for p in [arrival,spin,reveal,accent]:
        if is_instance_valid(p):p.stream_paused=false;p.stop()
    if not was_active:return
    restore_count+=1
    if is_instance_valid(session.camera) and not saved.is_empty():
        session.camera.transform=saved.transform;session.camera.fov=saved.fov;session.camera.near=saved.near;session.camera.far=saved.far;session.camera.environment=saved.environment
        session.audio.cinematic_duck=saved.duck;session.backdrop.visible=saved.backdrop;session.backdrop.living.visible=saved.living
    for a in saved_actors:if is_instance_valid(a.node):a.node.visible=a.visible
    for a in saved_shadows:if is_instance_valid(a.node):a.node.visible=a.visible
    saved.clear();saved_actors.clear();saved_shadows.clear()
    session.pending.clear()
