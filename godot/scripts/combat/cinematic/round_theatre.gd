extends Node3D
## Entry and bounded combat accents share one lens; KO has higher ownership.
const Tokens=preload("res://scripts/combat/ui/ui_theme.gd")
const INTRO_SECONDS:=2.8
var session:Node3D
var intro:=false
var age:=0.0
var close_age:=1.0
var close_duration:=.28
var cooldown:=0.0
var close_count:=0
var saved_near:=.1
var saved_visibility:Array=[]
var portrait=preload("res://scripts/combat/cinematic/victory_exit.gd").new()
var framing=preload("res://scripts/combat/neon/neon_signature_camera.gd").new()
var lens:ColorRect
var material:ShaderMaterial
var score:AudioStreamPlayer
func setup(owner_session:Node3D) -> void:
    session=owner_session;name="RoundPresentation"
    var layer:=CanvasLayer.new();layer.layer=1;add_child(layer)
    lens=ColorRect.new();lens.mouse_filter=Control.MOUSE_FILTER_IGNORE
    lens.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    material=ShaderMaterial.new();material.shader=preload("res://shaders/city_breaker_lens.gdshader")
    lens.material=material;layer.add_child(lens);lens.hide()
    score=AudioStreamPlayer.new();score.stream=load("res://audio/city_breaker/intro.wav");score.bus="Afterhours SFX";add_child(score)
func begin_intro() -> void:
    clear()
    if session.sim.squad_enabled:return
    saved_near=session.camera.near
    saved_visibility.clear()
    for actor in session.fighters:saved_visibility.append(actor.visible)
    intro=true;age=0.0
    score.volume_db=-80.0 if session.audio.muted or session.audio.effects_level<=0 else -9.0+linear_to_db(session.audio.effects_level)
    score.play()
    sample_intro()
func clear() -> void:
    if is_instance_valid(session) and is_instance_valid(session.camera):
        if intro:session.camera.near=saved_near
        for i in saved_visibility.size():
            if i<session.fighters.size():session.fighters[i].visible=saved_visibility[i]
    intro=false;age=0.0;close_age=1.0;cooldown=0
    if is_instance_valid(lens):lens.hide();material.set_shader_parameter("fisheye",0.0)
    if is_instance_valid(score):
        score.stream_paused=false
        if score.has_stream_playback():score.get_stream_playback().stop()
        score.stop()
    if is_instance_valid(session) and is_instance_valid(session.audio):session.audio.cinematic_duck=0.0
func hold_simulation() -> bool:
    # Explicit test/training fixtures that enter fight cannot inherit an intro lock.
    if intro and session.sim.phase!="ready":clear()
    return intro
func trigger(event:Dictionary) -> void:
    if session.sim.last_service_enabled and event.get("move","")=="special" and session.sim.fighters[clampi(event.get("attacker",0),0,1)].character==0:return
    if session.sim.squad_enabled:return
    if intro or cooldown>0 or session.screen!="play" or session.reduced_effects:return
    if event.kind!="hit" or event.get("move","") not in ["heavy","finisher","launcher","meteor","special","overdrive","air_counter"]:return
    if event.get("target",-1) not in [0,1] or session.sim.fighters[event.target].health<=0:return
    close_age=0.0;cooldown=1.6;close_count+=1
func advance(delta:float,paused:bool) -> void:
    if intro:
        if session.reduced_effects:clear();return
        score.stream_paused=paused
        score.volume_db=-80.0 if session.audio.muted or session.audio.effects_level<=0 else -9.0+linear_to_db(session.audio.effects_level)
        if not paused:age+=delta
        if age>=INTRO_SECONDS:clear();session.pending.clear();return
        sample_intro()
        return
    if paused:return
    cooldown=maxf(0,cooldown-delta)
    lens.hide()
    if session.sim.last_service_enabled and session.sim.fighters.any(func(f:Dictionary)->bool:return f.character==0 and f.health>0 and f.state=="attack" and f.move=="special"):
        close_age=1.0
        return
    if session.neon.signature:close_age=1.0;return
    if session.neon.stage():return
    close_age+=delta
    if session.screen!="play" or session.reduced_effects or session.sim.phase!="fight" or session.city_breaker.active():close_age=1.0;return
    if close_age>=close_duration or session.neon.signature or session.neon.stage():return
    var strength:float=sin(clampf(close_age/close_duration,0,1)*PI)
    var a:Dictionary=session.sim.fighters[0];var b:Dictionary=session.sim.fighters[1]
    var center:=Vector3((a.x+b.x)*.5,(minf(a.y,b.y)+maxf(a.y,b.y)+2.35)*.5,session.FIGHT_Z)
    var distance:float=maxf(3.1,session.camera.position.distance_to(center)*.56)
    var original:Transform3D=session.camera.transform
    var fov:float=session.camera.fov
    session.camera.position=center+Vector3(.22,0,distance);session.camera.look_at(center);session.camera.fov=78
    for i in 10:
        if safe_framing():break
        session.camera.position=center+(session.camera.position-center)*1.12
    var target:Transform3D=session.camera.transform
    session.camera.transform=original.interpolate_with(target,strength)
    session.camera.fov=lerpf(fov,78,strength)
    # Recheck the blended camera, preserving both bodies and the HUD margins.
    for i in 8:
        if safe_framing():break
        session.camera.position=center+(session.camera.position-center)*1.1
    material.set_shader_parameter("fisheye",strength*.32)
    material.set_shader_parameter("impact",strength*.12)
    material.set_shader_parameter("blur",strength*.012)
    material.set_shader_parameter("center",Vector2(.5,.5));lens.show()
func sample_intro() -> void:
    for i in 2:
        session.fighters[i].visible=true
        session.fighters[i].present(session.sim.fighters[i].duplicate(),0.0,true,false,session.sim.fighters[1-i].x)
    session.backdrop.visible=true;session.camera.environment=null
    material.set_shader_parameter("fisheye",0.0);material.set_shader_parameter("blur",.014);material.set_shader_parameter("impact",0.0)
    if age>=.35 and age<1.85:
        var side:=0 if age<1.10 else 1
        var local:float=age-(.35 if side==0 else 1.10)
        portrait.apply(session,side,.2+local*.7)
        session.fighters[1-side].visible=false
        # Less extreme than the winner exit; enough room for the entry gesture.
        session.camera.position.z+=.30
        material.set_shader_parameter("fisheye",.48)
        material.set_shader_parameter("impact",maxf(0,.12-local)*2.0)
    else:
        var center:=Vector3((session.sim.fighters[0].x+session.sim.fighters[1].x)*.5,1.15,session.FIGHT_Z)
        session.camera.position=center+Vector3(-.4,1.1,7.7)
        session.camera.look_at(center);session.camera.fov=62
        session.camera.rotation.z=deg_to_rad(-3)*sin(age*1.6)
    session.audio.cinematic_duck=.45
    lens.show()
func draw(canvas:Control) -> void:
    if not intro:return
    var ink:=Tokens.INK;var color:=Tokens.LIME
    canvas.draw_rect(Rect2(0,0,1280,35),ink);canvas.draw_rect(Rect2(0,650,1280,70),ink)
    canvas.draw_string(session.hud.font,Vector2(30,695),"ENTER / SPACE  SKIP    ESC  PAUSE",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Tokens.PAPER)
    if age<.35 or age>=1.85:
        var title:="ROUND %02d"%session.presentation_round()
        var width:float=session.hud.bold.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,90).x
        canvas.draw_string(session.hud.bold,Vector2(640-width*.5+5,430),title,HORIZONTAL_ALIGNMENT_LEFT,-1,90,ink)
        canvas.draw_string(session.hud.bold,Vector2(640-width*.5,424),title,HORIZONTAL_ALIGNMENT_LEFT,-1,90,color)
        if age<.35:canvas.draw_string(session.hud.bold,Vector2(582,520),"VS",HORIZONTAL_ALIGNMENT_LEFT,-1,68,Tokens.MAGENTA)
    else:
        var side:=0 if age<1.10 else 1
        var id:int=session.fighters[side].character_index
        var text:String="P%d / "%int(side+1)+["ZIP","RIVET","HUSH","LOOP","BLACK SUIT"][id]
        canvas.draw_string(session.hud.bold,Vector2(62,605),text,HORIZONTAL_ALIGNMENT_LEFT,-1,74,Tokens.TEAL if side==0 else Tokens.MAGENTA)
        if side==1 and not session.intro_line.is_empty():
            canvas.draw_string(session.hud.font,Vector2(62,642),session.intro_line,HORIZONTAL_ALIGNMENT_LEFT,1150,28,Tokens.PAPER)

func safe_framing() -> bool:
    if not framing.fits(session.camera,session):return false
    var extent:Vector2=session.get_viewport().get_visible_rect().size
    for f in session.sim.fighters:
        for y in [0.0,2.35]:
            var point:=Vector3(f.x,f.y+y,session.FIGHT_Z)
            var uv:Vector2=session.camera.unproject_position(point)/extent
            if uv.y<.25 or uv.y>.75:return false
    return true


func _exit_tree() -> void:
    if is_instance_valid(score):
        score.stream_paused=false
        if score.has_stream_playback():score.get_stream_playback().stop()
        score.stop();score.stream=null
