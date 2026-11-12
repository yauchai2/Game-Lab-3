extends Node3D
## Boot story opening: 18 seconds, six shots, real-time 3D with the roster models.
## One stateless authored timeline (sample(t) is repeatable), its own lens and score.
## Owns the session camera only while running; clear() restores everything it touched.
## Presentation only: no simulation, XP or combat state is read or written.
const Stage=preload("res://scripts/combat/story_opening/stage.gd")
const Actor=preload("res://scripts/combat/story_opening/actor.gd")
const DURATION:=18.0
const CUTS:=[0.0,3.0,6.0,9.0,12.0,15.0,18.0]
const SHOTS:=["CITY AWAKE","FOUR LIVES","ZIP RETURNS","WRONG DELIVERY","COLLECTORS","TITLE DROP"]
const ORIGIN:=Vector3(2400,0,0)
const TITLE_AT:=16.1
const SLAM_AT:=16.0
const MUSIC_CUT:=9.75
## The menu track fades back in here, under the score's sign-off bar.
const MENU_MUSIC_AT:=17.0
## [time, strength] camera trauma. Mirrors the cue sheet in audio/story_opening/cues.json.
const IMPACTS:=[[6.55,.55],[6.98,.3],[8.0,1.0],[9.15,.22],[9.45,.22],[12.78,.45],[13.1,.6],[13.55,.4],[13.85,.4],[14.2,.18],[16.0,1.3],[16.1,.9]]
const SUBTITLES:=[
	{"from":4.55,"to":5.9,"who":"LOOP","color":Color("c4ff00"),"zh":"「件貨呢？」","en":"\"Where's the parcel?\""},
	{"from":6.95,"to":7.95,"who":"ZIP","color":Color("00e9ef"),"zh":"「到咗。」","en":"\"It's here.\""},
	{"from":10.35,"to":11.9,"who":"LOOP","color":Color("c4ff00"),"zh":"「……我買音響喎。」","en":"\"...I ordered speakers.\""}]
const TAGS:=[[3.15,4.1,"RIVET",Color("ff9824")],[4.1,5.0,"LOOP",Color("c4ff00")],[5.0,5.95,"HUSH",Color("ff3d97")],[7.0,7.7,"ZIP",Color("00e9ef")]]
const SUIT_MARKS:=[Vector3(.1,0,4.0),Vector3(-1.5,0,4.35),Vector3(1.7,0,4.35)]
const TITLE_MARKS:=[Vector3(.3,27.0,-1.5),Vector3(-1.25,27.0,-1.45),Vector3(-4.1,27.0,-1.45),Vector3(-2.75,27.0,-1.5)]
const TITLE_FLOOR:=27.0

var session:Node3D
var running:=false
var paused:=false
var replay:=false
var age:=0.0
var shot:=0
var seen:=false
var save_path:=""
var stage:Node3D
var cast:Array[Node3D]=[]
var suits:Array[Node3D]=[]
var puffs:Array[MeshInstance3D]=[]
var environment:Environment
var lens:ColorRect
var material:ShaderMaterial
var logo:TextureRect
var logo_shadow:TextureRect
var score:AudioStreamPlayer
var subtitle_font:Font
var saved:Dictionary={}
var hidden:Array[Dictionary]=[]
var shake:=0.0
var speed_radial:=0.0
var speed_side:=0.0
var focus:=Vector2(640,360)
var music_was_cut:=false
var finished_count:=0
## Review/capture tools hold the clock and scrub with sample(t).
var scrub:=false

func setup(owner_session:Node3D) -> void:
	session=owner_session;name="StoryOpening"
	var base:String=session.progression_path
	save_path="" if base.is_empty() else base.get_base_dir().path_join("story_opening.cfg")
	_load_seen()
	var layer:=CanvasLayer.new();layer.layer=1;add_child(layer)
	lens=ColorRect.new();lens.name="StoryOpeningLens";lens.mouse_filter=Control.MOUSE_FILTER_IGNORE
	lens.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	material=ShaderMaterial.new();material.shader=preload("res://shaders/story_opening_lens.gdshader")
	lens.material=material;layer.add_child(lens);lens.hide()
	# Wordmark is white on black: additive over the sky, subtractive copy as its shadow.
	var mark:=AtlasTexture.new();mark.atlas=preload("res://assets/ui/ink/logo-source.png");mark.region=Rect2(96,204,1990,286)
	for mode in [CanvasItemMaterial.BLEND_MODE_SUB,CanvasItemMaterial.BLEND_MODE_ADD]:
		var rect:=TextureRect.new();rect.texture=mark;rect.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;rect.stretch_mode=TextureRect.STRETCH_SCALE
		rect.mouse_filter=Control.MOUSE_FILTER_IGNORE;rect.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		var blend:=CanvasItemMaterial.new();blend.blend_mode=mode;rect.material=blend
		layer.add_child(rect);rect.hide()
		if mode==CanvasItemMaterial.BLEND_MODE_ADD:logo=rect
		else:logo_shadow=rect
	score=AudioStreamPlayer.new();score.name="StoryOpeningScore";score.bus="Afterhours SFX"
	if ResourceLoader.exists("res://audio/story_opening/score.wav"):score.stream=load("res://audio/story_opening/score.wav")
	add_child(score)
	if ResourceLoader.exists("res://assets/fonts/StoryOpeningHK.otf"):subtitle_font=load("res://assets/fonts/StoryOpeningHK.otf")

func _load_seen() -> void:
	seen=false
	if save_path.is_empty():return
	var file:=ConfigFile.new()
	if file.load(save_path)==OK:seen=file.get_value("story_opening","seen",false)==true

func mark_seen() -> void:
	seen=true
	if save_path.is_empty():return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(save_path.get_base_dir()))
	var file:=ConfigFile.new();file.set_value("story_opening","version",1);file.set_value("story_opening","seen",true)
	file.save(save_path)

func active() -> bool:return running

func begin(as_replay:=false) -> void:
	clear()
	replay=as_replay
	if stage==null:_prepare()
	saved={"transform":session.camera.transform,"fov":session.camera.fov,"near":session.camera.near,"far":session.camera.far,"environment":session.camera.environment,"screen":session.screen}
	hidden.clear()
	var nodes:Array=[session.backdrop]+session.fighters+session.silhouettes+session.squad_visuals
	for node in nodes:
		if is_instance_valid(node):hidden.append({"node":node,"visible":node.visible});node.visible=false
	stage.show()
	session.camera.environment=environment;session.camera.near=.05;session.camera.far=420.0
	running=true;paused=false;age=0.0;music_was_cut=false
	session.screen="opening"
	session.pending.clear()
	session.hud.rebuild_menu()
	_sync_audio()
	if score.stream!=null:score.play()
	sample(0.0)

func _prepare() -> void:
	stage=Stage.new();stage.name="StoryOpeningStage";add_child(stage);stage.position=ORIGIN;stage.build()
	for id in 4:
		var actor:Node3D=Actor.new();actor.name=["Zip","Rivet","Hush","Loop"][id];stage.add_child(actor);actor.setup(id);cast.append(actor)
	for id in 3:
		var suit:Node3D=Actor.new();suit.name="Collector%d"%id;stage.add_child(suit);suit.setup(4);suits.append(suit)
	var smoke:=StandardMaterial3D.new();smoke.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;smoke.albedo_color=Color("d9d2dc")
	for i in 48:
		var puff:=MeshInstance3D.new();var ball:=SphereMesh.new();ball.radius=.5;ball.height=.8;ball.radial_segments=6;ball.rings=3
		puff.mesh=ball;puff.material_override=smoke;puff.hide();stage.add_child(puff);puffs.append(puff)
	environment=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.background_color=Stage.SKY
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color("e2cdea");environment.ambient_light_energy=.8

func advance(delta:float) -> void:
	if not running:return
	_sync_audio()
	if paused:return
	if scrub:sample(age);return
	age+=maxf(0.0,delta)
	if age>=DURATION:finish(false);return
	sample(age)

func finish(skipped:bool) -> void:
	if not running:return
	finished_count+=1
	if not seen:mark_seen()
	clear()
	# Music always resumes at menu level, including after a skip during the silence.
	session.audio.cinematic_duck=0.0
	if skipped and music_was_cut:session.audio.music_gain_db=-12.0
	session.screen="title"
	session.pending.clear()
	session.hud.rebuild_menu()

func handle_key(event:InputEvent) -> bool:
	if not running or not event.is_pressed() or event.is_echo():return running
	if event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:finish(true)
	elif event.keycode==KEY_ESCAPE:
		paused=not paused;_sync_audio()
	elif event.keycode==KEY_F2:
		session.reduced_effects=not session.reduced_effects;session.save_options();sample(age)
	elif event.keycode==KEY_M:
		session.audio.muted=not session.audio.muted;session.save_options()
	return true

func clear() -> void:
	var was_running:=running
	running=false;paused=false
	if is_instance_valid(score):
		score.stream_paused=false
		score.stop()
	if is_instance_valid(lens):lens.hide()
	if is_instance_valid(logo):logo.hide();logo_shadow.hide()
	if is_instance_valid(stage):stage.hide()
	shake=0.0;speed_radial=0.0;speed_side=0.0
	if not was_running or not is_instance_valid(session):return
	for entry in hidden:
		if is_instance_valid(entry.node):entry.node.visible=entry.visible
	hidden.clear()
	if is_instance_valid(session.camera) and not saved.is_empty():
		session.camera.transform=saved.transform;session.camera.fov=saved.fov
		session.camera.near=saved.near;session.camera.far=saved.far;session.camera.environment=saved.environment
	if is_instance_valid(session.audio):session.audio.cinematic_duck=0.0
	saved.clear()

func _sync_audio() -> void:
	var audio:Node=session.audio
	score.stream_paused=paused
	score.volume_db=-80.0 if audio.muted or audio.effects_level<=0 else -1.0+linear_to_db(maxf(.001,audio.effects_level))
	# The baked score carries its own beat, so the menu track stays silent under it
	# and fades back in once the title has hit. The transport itself never stops.
	var silent:=age<MENU_MUSIC_AT
	audio.cinematic_duck=10.0 if silent else (1.5 if paused else 0.0)
	if silent:
		music_was_cut=true;audio.music_gain_db=-80.0
	elif music_was_cut:
		music_was_cut=false
		if not (audio.muted or audio.music_muted or audio.music_level<=0):audio.music_gain_db=-34.0

# ---------------------------------------------------------------- timeline

static func seg(t:float,a:float,b:float) -> float:return clampf((t-a)/(b-a),0.0,1.0)
static func ease_io(u:float) -> float:return u*u*(3.0-2.0*u)
func w(point:Vector3) -> Vector3:return ORIGIN+point

func shot_at(t:float) -> int:
	for i in 6:
		if t<CUTS[i+1]:return i
	return 5

func trauma_at(t:float) -> float:
	var total:=0.0
	for hit in IMPACTS:
		var dt:float=t-hit[0]
		if dt>=0 and dt<.6:total+=hit[1]*exp(-dt*8.5)
	return minf(total,1.4)

func sample(t:float) -> void:
	age=t;shot=shot_at(t)
	var reduced:bool=session.reduced_effects
	stage.pose_train(t)
	stage.pose_walkers(t)
	_cast_at(t)
	_props_at(t)
	_puffs_at(t,reduced)
	var cam:Dictionary=_camera_at(t)
	shake=0.0 if reduced else trauma_at(t)
	var camera:Camera3D=session.camera
	var at:Vector3=cam.at
	if shake>0:at+=Vector3(sin(t*83.0),sin(t*97.0+1.3),sin(t*71.0+.4))*shake*cam.get("shake",.09)
	camera.global_position=w(at)
	camera.look_at(w(cam.look),cam.get("up",Vector3.UP))
	camera.rotate_object_local(Vector3.BACK,deg_to_rad(cam.get("roll",0.0))+sin(t*61.0)*shake*.03)
	camera.fov=cam.fov
	_lens_at(t,cam,reduced)
	_logo_at(t,reduced)

func _camera_at(t:float) -> Dictionary:
	var table:Vector3=Stage.TABLE
	if t<3.0:
		# Dive from beside the train, through the wires, down to the garage door.
		var u:=ease_io(seg(t,0,3.0));var v:=pow(seg(t,0.0,3.0),1.6)
		var start:=Vector3(27,12.9,17.4);var mid:=Vector3(18,9.6,12.5);var end:=Vector3(5.2,1.9,5.6)
		var at:Vector3=start.lerp(mid,v).lerp(mid.lerp(end,v),v)
		var look:Vector3=Vector3(6,10.5,21).lerp(Vector3(0,1.9,-2.5),ease_io(seg(t,.35,2.4)))
		return {"at":at,"look":look,"fov":lerpf(84,60,u),"roll":lerpf(-16,2,u),"fisheye":lerpf(.62,.2,u),"blur":sin(seg(t,.4,2.8)*PI)*.05,"radial":sin(seg(t,.5,2.8)*PI)*.8}
	if t<6.0:
		# Lateral track through the workshop: three short holds joined by whip moves.
		var stops:=[Vector3(-3.25,1.3,-.55),Vector3(1.05,1.05,-.15),Vector3(2.85,1.2,-1.55)]
		var looks:=[Vector3(-3.9,.85,-3.5),Vector3(1.1,.75,-2.8),Vector3(4.5,1.0,-3.35)]
		var i:=0 if t<4.1 else 1
		var move:=seg(t,3.8,4.1) if t<4.1 else seg(t,4.9,5.2)
		var f:=ease_io(move);var whip:=sin(move*PI)
		var drift:=Vector3((t-3.0)*.12,0,0)
		return {"at":stops[i].lerp(stops[i+1],f)+drift,"look":looks[i].lerp(looks[i+1],f)+drift*.5,"fov":56.0-whip*4.0,"roll":-3.0+whip*6.0,"fisheye":.2,"smear":whip*.04,"side":whip*.8}
	if t<7.7:
		# Ground-level wide: the sole lands in the doorway, then tilt up to ZIP and the case.
		var tilt:=ease_io(seg(t,6.7,7.45))
		return {"at":Vector3(-.5,.13,-2.5).lerp(Vector3(-.62,.42,-2.95),tilt),"look":Vector3(.0,.3,-.6).lerp(Vector3(.12,1.5,-1.75),tilt),"fov":lerpf(98,80,tilt),"roll":lerpf(-7,-2,tilt),"fisheye":lerpf(.85,.5,tilt),"chroma":.004,"shake":.06}
	if t<9.0:
		# Case slams onto the bench; punch in after the hit.
		var push:=ease_io(seg(t,8.0,9.0))
		var pre:=seg(t,7.7,8.0)
		return {"at":table+Vector3(-1.75,.42,-1.5).lerp(Vector3(-1.2,.3,-1.25),push)+Vector3(0,(1-pre)*.25,0),"look":table+Vector3(0,.22+(1-pre)*.5,0),"fov":lerpf(64,50,push),"roll":4.0-push*3.0,"fisheye":.3,"blur":maxf(0,1-absf(t-8.0)/.16)*.07,"radial":maxf(0,1-absf(t-8.02)/.3),"shake":.12}
	if t<MUSIC_CUT:
		# Latches: close, shallow, silent push.
		var u:=seg(t,9.0,MUSIC_CUT)
		return {"at":table+Vector3(1.25,.55,-2.0).lerp(Vector3(.95,.48,-1.75),u),"look":table+Vector3(0,.14,-.3),"fov":40,"roll":-2.0,"fisheye":.1,"shake":.035}
	if t<12.0:
		# Hard cut to the overhead: contents, manifest, four frozen heads.
		var u:=seg(t,MUSIC_CUT,12.0)
		return {"at":table+Vector3(.02,lerpf(3.7,3.1,ease_io(u)),.16),"look":table+Vector3(0,.2,.18),"up":Vector3(sin(deg_to_rad(lerpf(-4,7,u))),0,-cos(deg_to_rad(lerpf(-4,7,u)))),"fov":70,"fisheye":.62,"chroma":.003,"vignette":.55}
	if t<12.88:
		# The black car brakes in, seen low from the kerb.
		var u:=seg(t,12.0,12.88)
		return {"at":Vector3(6.4,.34,2.9),"look":Vector3(lerpf(9,-.5,ease_io(u)),.75,6.2),"fov":62,"roll":-5.0,"fisheye":.35,"smear":(1-u)*.045,"side":(1-u)*1.0,"shake":.07}
	if t<13.3:
		# Three doors, one beat.
		return {"at":Vector3(-3.6,.5,2.6),"look":Vector3(.4,.95,5.6),"fov":54,"roll":5.0,"fisheye":.3,"shake":.08}
	if t<14.0:
		# Low on the polished shoes, in step.
		var u:=seg(t,13.3,14.0)
		return {"at":Vector3(.5,.1,2.05+u*.12),"look":Vector3(.1,.42,4.0),"fov":76,"roll":-4.0,"fisheye":.7,"chroma":.004,"shake":.07}
	if t<15.0:
		# Push in on the leader's sunglasses while the glove is pulled tight.
		var u:=ease_io(seg(t,14.0,15.0))
		var head:Vector3=suits[0].point("Head")-ORIGIN+Vector3(0,.1,0)
		return {"at":Vector3(.75,1.25,1.5).lerp(head+Vector3(.16,-.06,-.82),u),"look":head,"fov":lerpf(52,34,u),"roll":lerpf(6,0,u),"fisheye":lerpf(.3,.5,u),"blur":u*.018,"radial":u*.5,"shake":.03}
	if t<15.55:
		# From the bench: ZIP's back, the open case, and the collectors framed in the door.
		var u:=ease_io(seg(t,15.0,15.55))
		return {"at":Vector3(1.45,1.78,-7.5).lerp(Vector3(1.3,1.72,-7.0),u),"look":Vector3(-.1,1.25,4.2),"fov":lerpf(58,33,u),"roll":-3.0,"fisheye":.15,"blur":sin(u*PI)*.04,"radial":sin(u*PI)*.7}
	if t<TITLE_AT:
		# Inside the case looking up: the lid comes down on the lens.
		return {"at":table+Vector3(.05,.215,-.08),"look":table+Vector3(.0,1.25,.62),"fov":104,"roll":3.0,"fisheye":.85,"chroma":.006,"shake":.02}
	# Title: behind the four on the ledge, city in ink beyond.
	var u:=seg(t,TITLE_AT,DURATION)
	return {"at":Vector3(.9,27.3,-9.7+u*.35),"look":Vector3(-.35,28.7+u*.08,10),"fov":40,"roll":-1.5,"fisheye":.1,"ink":1.0,"vignette":.0,"shake":.1}

func _lens_at(t:float,cam:Dictionary,reduced:bool) -> void:
	lens.visible=running
	var trauma:=0.0 if reduced else trauma_at(t)
	material.set_shader_parameter("fisheye",0.0 if reduced else cam.get("fisheye",0.0))
	material.set_shader_parameter("blur",0.0 if reduced else cam.get("blur",0.0)+trauma*.02)
	material.set_shader_parameter("smear",Vector2.ZERO if reduced else Vector2(cam.get("smear",0.0),0))
	material.set_shader_parameter("chroma",0.0 if reduced else cam.get("chroma",0.0)+trauma*.006)
	material.set_shader_parameter("vignette",cam.get("vignette",.3))
	material.set_shader_parameter("ink",cam.get("ink",0.0))
	speed_radial=0.0 if reduced else cam.get("radial",0.0)
	speed_side=0.0 if reduced else cam.get("side",0.0)
	var flash:=0.0;var fade:=0.0;var invert:=0.0
	if not reduced:
		flash=maxf(maxf(0,1-absf(t-8.01)/.07)*.3,maxf(0,1-(t-TITLE_AT)/.26) if t>=TITLE_AT else 0.0)
		if t>=9.75 and t<9.83:flash=maxf(flash,.5)
		if t>=SLAM_AT-.02 and t<SLAM_AT+.04:invert=1.0
	if t>=SLAM_AT and t<TITLE_AT:fade=1.0
	if t<.25:fade=1.0-t/.25
	if t>DURATION-.12:flash=maxf(flash,(t-(DURATION-.12))/.12*(0.0 if reduced else .6))
	material.set_shader_parameter("flash",flash)
	material.set_shader_parameter("fade",fade)
	material.set_shader_parameter("invert",invert)

func _logo_at(t:float,reduced:bool) -> void:
	var show_logo:=running and t>=TITLE_AT
	logo.visible=show_logo;logo_shadow.visible=show_logo
	if not show_logo:return
	var extent:Vector2=session.get_viewport().get_visible_rect().size
	var unit:float=extent.x/640.0
	var land:=1.0 if reduced else seg(t,TITLE_AT,TITLE_AT+.2)
	var size:=Vector2(372,372.0*286.0/1990.0)*unit
	var zoom:=lerpf(2.7,1.0,1.0-pow(1.0-land,3.0))
	var jolt:=Vector2.ZERO if reduced else Vector2(sin(t*90.0),cos(t*77.0))*trauma_at(t)*5.0*unit
	for rect in [logo_shadow,logo]:
		rect.size=size;rect.pivot_offset=size*.5;rect.scale=Vector2.ONE*zoom;rect.rotation=deg_to_rad(-5.0)
		rect.position=Vector2(26,30)*unit+jolt+(Vector2(4,4)*unit if rect==logo_shadow else Vector2.ZERO)
		rect.modulate=Color(1,1,1,land)

# ---------------------------------------------------------------- performers

func _lean(actor:Node3D,amount:float) -> void:
	actor.aim("Spine","Spine1",Vector3.UP+actor.forward()*amount,1.0)
	actor.aim("Neck","Head",Vector3.UP*.55+actor.forward()*amount*1.5,1.0)

func _arms_down(actor:Node3D) -> void:
	for side in ["Left","Right"]:
		var out:Vector3=actor.right()*(.16 if side=="Right" else -.16)
		actor.aim(side+"Arm",side+"ForeArm",Vector3.DOWN+out+actor.forward()*.05,.95)
		actor.aim(side+"ForeArm",side+"Hand",Vector3.DOWN+out*.5+actor.forward()*.2,.95)

func _cast_at(t:float) -> void:
	var zip:Node3D=cast[0];var rivet:Node3D=cast[1];var hush:Node3D=cast[2];var loop:Node3D=cast[3]
	var table:Vector3=Stage.TABLE
	var title:=t>=TITLE_AT
	var gathered:=t>=MUSIC_CUT and not title
	for actor in cast:
		actor.visible=true;actor.visual.set_neon_silhouette(title)
	zip.visible=t>=6.0
	if title:
		# Backs to camera on the ledge, four distinct stances.
		for i in 4:
			var actor:Node3D=cast[i]
			actor.place(TITLE_MARKS[i],[8.0,-4.0,10.0,-12.0][i])
			actor.clip("Idle_Loop",t*.6+i*.7)
		for side in ["Left","Right"]:
			var out:Vector3=zip.right()*(1.0 if side=="Right" else -1.0)
			zip.aim(side+"Arm",side+"ForeArm",Vector3.DOWN*.75+out*.8-zip.forward()*.25,1.0)
			zip.aim(side+"ForeArm",side+"Hand",Vector3.DOWN*.5-out*.9+zip.forward()*.3,1.0)
		_arms_down(rivet)
		for side in ["Left","Right"]:
			var out:Vector3=rivet.right()*(.45 if side=="Right" else -.45)
			rivet.aim(side+"Arm",side+"ForeArm",Vector3.DOWN+out,1.0)
		_arms_down(hush);_arms_down(loop)
		loop.aim("RightArm","RightForeArm",Vector3.DOWN*.4+loop.right()*.9,1.0)
		loop.aim("RightForeArm","RightHand",Vector3.UP*.8+loop.right()*.3,1.0)
		for actor in cast:actor.finish(TITLE_FLOOR,false)
	elif gathered:
		# Around the bench. Frozen at the reveal; heads snap to the door when the car arrives.
		var alert:=t>=15.0
		var spots:=[[Vector3(table.x,0,table.z+1.02),180.0],[Vector3(table.x-1.72,0,table.z-.1),90.0],[Vector3(table.x+.25,0,table.z-1.18),0.0],[Vector3(table.x+1.72,0,table.z-.15),-90.0]]
		for i in 4:
			var actor:Node3D=cast[i]
			actor.place(spots[i][0],spots[i][1])
			actor.clip("Idle_Loop",.4+i*.5+(t-MUSIC_CUT)*.04)
			_arms_down(actor)
			if alert and i>0:
				var away:Vector3=(Vector3(0,1.4,4)-spots[i][0]).normalized()
				actor.twist("Spine1",Vector3.UP,clampf(actor.forward().signed_angle_to(away,Vector3.UP),-1.0,1.0)*.55)
				actor.twist("Head",Vector3.UP,clampf(actor.forward().signed_angle_to(away,Vector3.UP),-1.0,1.0)*.45)
			else:_lean(actor,.5 if i!=1 else .42)
		if t>=15.0 and t<15.55:
			# ZIP has turned to the door.
			zip.place(Vector3(table.x-.05,0,table.z+1.05),0.0);zip.clip("Idle_Loop",.4);_arms_down(zip)
		elif t>=15.55:
			# ZIP's hand on the lid, driving it shut.
			var grip:Vector3=stage.case_lid.to_global(Vector3(-.12,.14,-.62))
			_lean(zip,.75)
			zip.reach("Right",grip,grip+Vector3(-.6,.4,.5))
		if not alert:rivet.reach("Right",w(table+Vector3(-.9,.06,-.1)),w(table+Vector3(-1.6,.6,-.8)))
		for actor in cast:actor.finish(0.0)
	else:
		# Daily life: RIVET on the bike, LOOP on the speaker, HUSH on the sofa.
		var notice:=ease_io(seg(t,6.3,6.8))
		rivet.place(Vector3(-3.85,0,-3.82),4.0)
		rivet.clip("Crouch_Idle_Loop",t)
		rivet.ground(0.0)
		var crank:=sin(t*9.0)*(1.0-notice)
		var bolt:Vector3=w(Vector3(-3.72,.66+crank*.05,-3.18))
		rivet.reach("Right",bolt+Vector3(.02,.08,-.2+crank*.04),bolt+Vector3(.9,-.3,-.6))
		rivet.reach("Left",w(Vector3(-4.38,.95,-3.2)),w(Vector3(-5.2,.4,-3.9)))
		rivet.twist("Head",Vector3.UP,notice*.5)
		stage.wrench.global_position=rivet.point("RightHand")
		stage.wrench.global_rotation=Vector3(deg_to_rad(-20+crank*22.0),deg_to_rad(10),0)
		loop.place(Vector3(.72,0,-2.95),74.0)
		loop.clip("Crouch_Idle_Loop",t+1.1)
		loop.ground(0.0)
		var fiddle:=sin(t*17.0)*.03*(1.0-notice)
		loop.reach("Right",w(Vector3(1.22,.9+fiddle,-2.45)),w(Vector3(.6,.4,-1.6)))
		loop.reach("Left",w(Vector3(1.2,.5,-3.0)),w(Vector3(.3,.1,-3.6)))
		loop.twist("Head",Vector3.UP,-.35*seg(t,4.5,4.8)*(1.0-notice)-notice*.9)
		hush.place(Vector3(4.42,0,-3.35),-90.0)
		hush.clip("Idle_Loop",t)
		for side in ["Left","Right"]:
			var spread:Vector3=hush.right()*(.22 if side=="Right" else -.22)
			hush.aim(side+"UpLeg",side+"Leg",hush.forward()+spread+Vector3.DOWN*.12,1.0)
			hush.aim(side+"Leg",side+"Foot",Vector3.DOWN+hush.forward()*.35,1.0)
		hush.aim("Spine","Spine1",Vector3.UP-hush.forward()*.3,1.0)
		hush.seat(.66)
		var nod:=sin(t*7.2)*.07
		hush.twist("Head",hush.right(),nod+.08)
		var sip:=ease_io(seg(t,5.05,5.3))*(1.0-seg(t,5.8,6.2))
		var mouth:Vector3=hush.point("Head")+hush.forward()*.2+Vector3.DOWN*.02
		var rest:Vector3=hush.point("Hips")+hush.forward()*.35+hush.right()*.2+Vector3.UP*.28
		hush.reach("Right",rest.lerp(mouth+Vector3.DOWN*.1,.55+sip*.45),rest+hush.right()*.6+Vector3.DOWN*.4)
		hush.aim("LeftArm","LeftForeArm",Vector3.DOWN*.7-hush.right()*.5+hush.forward()*.3,1.0)
		hush.aim("LeftForeArm","LeftHand",hush.forward()-hush.right()*.2+Vector3.DOWN*.2,1.0)
		stage.cup.global_position=hush.point("RightHand")+hush.forward()*.05+Vector3.UP*.04
		rivet.finish(0.0);loop.finish(0.0);hush.finish(0.0,false)
		if t>=6.0 and t<7.7:
			# The walk in. One heavy landing right in front of the lens.
			var travel:=seg(t,6.0,6.85)
			zip.place(Vector3(.12,0,lerpf(.5,-1.75,travel)),180.0)
			if travel<1.0:zip.clip("Walk_Loop",(t-6.0)*1.25+.2,3.2)
			else:zip.clip("Idle_Loop",t)
			zip.aim("LeftArm","LeftForeArm",Vector3.DOWN+zip.right()*-.15,.8)
			zip.aim("RightArm","RightForeArm",Vector3.DOWN+zip.right()*.2,1.0)
			zip.aim("RightForeArm","RightHand",Vector3.DOWN+zip.right()*.1,1.0)
			zip.finish(0.0)
		elif t>=7.7:
			zip.place(Vector3(table.x,0,table.z+1.02),180.0)
			zip.clip("Idle_Loop",t)
			var release:=seg(t,8.05,8.5)
			_lean(zip,.45*(1.0-release))
			var handle:Vector3=stage.case_root.to_global(Vector3(.1,.36,.3))
			if release<1.0:zip.reach("Right",handle.lerp(zip.point("Hips")+zip.right()*.34+Vector3.DOWN*.25,release),handle+zip.right()*.7+Vector3.UP*.3)
			zip.aim("LeftArm","LeftForeArm",Vector3.DOWN+zip.right()*-.15,.9)
			zip.finish(0.0)
	# Collectors.
	var arrived:=t>=12.95
	for i in 3:
		var suit:Node3D=suits[i];suit.visible=arrived
		if not arrived:continue
		var mark:Vector3=SUIT_MARKS[i]
		var step:=seg(t,12.95,14.0)
		var from:=Vector3(mark.x,0,5.15)
		suit.place(from.lerp(mark,step),180.0)
		if step<1.0:suit.clip("Walk_Loop",(t-12.95)*1.05,1.6)
		else:suit.clip("Idle_Loop",.3+(t-14.0)*.25)
		_arms_down(suit)
		if i==0 and t>=14.0 and t<TITLE_AT:
			# Pull the left glove tight across the chest.
			var raise:=ease_io(seg(t,14.0,14.25))
			var chest:Vector3=suit.point("Spine2") if suit.visual.motions.bone_index("Spine2")>=0 else suit.point("Hips")+Vector3.UP*.5
			var wrist:Vector3=chest+suit.forward()*.34+Vector3.DOWN*.08+suit.right()*-.06
			var arm:Vector3=suit.point("LeftArm")
			suit.reach("Left",arm.lerp(wrist,raise)+Vector3.DOWN*(1.0-raise)*.5,wrist+suit.right()*-.7+Vector3.DOWN*.5)
			var tug:=sin(seg(t,14.2,14.5)*PI)*.07
			suit.reach("Right",(suit.point("RightArm")+Vector3.DOWN*.5).lerp(wrist+suit.right()*(.1+tug)+Vector3.DOWN*.02,raise),wrist+suit.right()*.7+Vector3.DOWN*.5)
		suit.finish(-.1)

func _props_at(t:float) -> void:
	var table:Vector3=Stage.TABLE
	var case:Node3D=stage.case_root
	if t<6.0 or t>=TITLE_AT:
		case.visible=false
	elif t<7.7:
		# Carried on its side from ZIP's right hand.
		case.visible=true
		var hand:Vector3=cast[0].point("RightHand")
		var basis:=Basis(Vector3(0,0,-1),Vector3(1,0,0),Vector3(0,-1,0))
		var sway:=sin(t*7.0)*.04
		case.global_transform=Transform3D(basis.rotated(Vector3(1,0,0),sway),hand+Vector3(-.15+.02,-.12,0)+Vector3(0,-.02,0))
		stage.pose_case(0,0,0)
	else:
		case.visible=true
		var fall:=seg(t,7.7,8.0)
		var height:=(1.0-fall*fall)*.85
		if t>=8.0:height=maxf(0.0,sin(seg(t,8.0,8.16)*PI))*.035
		case.transform=Transform3D(Basis(Vector3.UP,deg_to_rad((1.0-fall)*9.0)).rotated(Vector3(1,0,0),(1.0-fall)*-.22),table+Vector3(0,height,0))
		var latch:=0.0
		if t>=9.15:latch=.5*seg(t,9.15,9.22)
		if t>=9.45:latch=.5+.5*seg(t,9.45,9.52)
		var open:=0.0
		if t>=9.5:open=.22*ease_io(seg(t,9.5,MUSIC_CUT))
		if t>=MUSIC_CUT:open=1.0
		if t>=15.55:open=1.0-pow(seg(t,15.68,SLAM_AT),2.6)
		var glow:=0.0
		if t>=9.5 and t<MUSIC_CUT:glow=.6*seg(t,9.5,MUSIC_CUT)
		elif t>=MUSIC_CUT and t<12.0:glow=lerpf(.35,.08,seg(t,MUSIC_CUT,10.6))
		stage.pose_case(open,latch,glow)
	stage.pose_table(seg(t,8.0,8.34) if t>=8.0 and t<8.34 else 0.0)
	# Fluorescent tubes stutter in the silence after the music is cut.
	var level:=1.0
	if t>=MUSIC_CUT and t<12.0 and not session.reduced_effects:
		level=.82+.18*signf(sin(t*31.0)+sin(t*47.0)+.9)
		if absf(t-10.05)<.05 or absf(t-11.2)<.04:level=.35
	stage.set_tube_flicker(level)
	stage.speaker_cone.scale=Vector3.ONE*(1.0+(.12*absf(sin(t*25.0)) if t>=3.0 and t<6.0 else 0.0))
	stage.wrench.visible=t<MUSIC_CUT;stage.cup.visible=t<MUSIC_CUT
	# Car: brake in, dip on the stop, doors open then slam together.
	var arrive:=seg(t,12.0,12.78)
	var x:=60.0 if t<12.0 else lerpf(34.0,.2,1.0-pow(1.0-arrive,2.4))
	var dip:=sin(seg(t,12.7,13.0)*PI) if t>=12.7 else 0.0
	var doors:=0.0
	if t>=12.88:doors=ease_io(seg(t,12.88,13.0))*(1.0-pow(seg(t,13.04,13.1),3.0))
	stage.pose_car(x,doors,dip)
	stage.ledge.visible=true

func _puffs_at(t:float,reduced:bool) -> void:
	# [time, centre, count, spread, life, size]; deterministic, capped at the pool.
	var bursts:=[[6.55,Vector3(.1,.02,-1.6),7,.8,.7,.22],[8.0,Stage.TABLE+Vector3(0,.02,0),12,1.3,.7,.2],[12.35,Vector3(7.5,.05,6.4),6,1.6,.9,.5],[12.7,Vector3(1.8,.05,6.4),8,1.8,1.0,.55],[13.55,Vector3(.1,.02,4.4),5,1.4,.5,.2],[13.85,Vector3(.1,.02,4.15),5,1.4,.5,.2]]
	var used:=0
	for burst in bursts:
		var life:float=(t-burst[0])/burst[4]
		for i in burst[2]:
			if used>=puffs.size():break
			var puff:MeshInstance3D=puffs[used];used+=1
			if life<0 or life>=1 or (reduced and i>2):puff.visible=false;continue
			var angle:float=i*2.399+burst[0]
			var reach:float=burst[3]*(1.0-pow(1.0-life,2.0))*(.55+.45*sin(i*1.7+1.0))
			puff.visible=true
			puff.position=burst[1]+Vector3(cos(angle)*reach,life*.5+sin(i*2.1)*.08+.1,sin(angle)*reach*.7)
			puff.scale=Vector3.ONE*burst[5]*(.5+life*1.3)*(1.0-life*life)
	for i in range(used,puffs.size()):puffs[i].visible=false

# ---------------------------------------------------------------- overlay

func project(local:Vector3) -> Vector2:
	var camera:Camera3D=session.camera
	if camera.is_position_behind(w(local)):return Vector2(-999,-999)
	return camera.unproject_position(w(local))/session.get_viewport().get_visible_rect().size*Vector2(1280,720)

func draw(canvas:Control) -> void:
	if not running:return
	var t:=age;var reduced:bool=session.reduced_effects
	var ink:=Color("0b0910");var bold:Font=session.hud.bold;var font:Font=session.hud.font
	if not reduced:
		_draw_radial(canvas,speed_radial,t)
		_draw_side(canvas,speed_side,t)
		_draw_accents(canvas,t)
	if t>=TITLE_AT:_draw_title(canvas,t,reduced)
	else:
		canvas.draw_rect(Rect2(0,0,1280,58),ink);canvas.draw_rect(Rect2(0,662,1280,58),ink)
	if t>=SLAM_AT and t<TITLE_AT and not reduced:_draw_slam(canvas,t)
	for tag in TAGS:
		if t<tag[0] or t>=tag[1]:continue
		var enter:=1.0 if reduced else 1.0-pow(1.0-seg(t,tag[0],tag[0]+.12),3.0)
		var leave:=seg(t,tag[1]-.1,tag[1])
		var x:=lerpf(-420,70,enter)+leave*-60.0
		canvas.draw_set_transform(Vector2(x,560)*canvas.size/Vector2(1280,720),-.07,canvas.size/Vector2(1280,720))
		var width:float=bold.get_string_size(tag[2],HORIZONTAL_ALIGNMENT_LEFT,-1,72).x+60
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(-20,-64),Vector2(width,-64),Vector2(width-26,22),Vector2(-46,22)]),ink)
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(width+6,-64),Vector2(width+30,-64),Vector2(width+4,22),Vector2(width-20,22)]),tag[3])
		canvas.draw_string(bold,Vector2(4,6),tag[2],HORIZONTAL_ALIGNMENT_LEFT,-1,72,tag[3])
		canvas.draw_set_transform(Vector2.ZERO,0,canvas.size/Vector2(1280,720))
	for line in SUBTITLES:
		if t<line.from or t>=line.to:continue
		# Cantonese is the authored line; English rides underneath for every player.
		var zh:bool=subtitle_font!=null
		var text:String=line.zh if zh else line.en
		var face:Font=subtitle_font if zh else font
		var size:=40 if zh else 30
		var width:float=face.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
		var name_width:float=bold.get_string_size(line.who,HORIZONTAL_ALIGNMENT_LEFT,-1,30).x
		var total:float=name_width+26+width
		var left:float=640-total*.5
		canvas.draw_rect(Rect2(left-22,596,total+44,56),Color(ink,.86))
		canvas.draw_rect(Rect2(left-22,596,8,56),line.color)
		canvas.draw_string(bold,Vector2(left,636),line.who,HORIZONTAL_ALIGNMENT_LEFT,-1,30,line.color)
		canvas.draw_string(face,Vector2(left+name_width+26,638 if zh else 635),text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color("f7f4ee"))
		if zh:canvas.draw_string(font,Vector2(left,682),line.en,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("bcb6c6"))
	if paused:
		canvas.draw_rect(Rect2(0,0,1280,720),Color(ink,.55))
		canvas.draw_string(bold,Vector2(70,372),"PAUSED",HORIZONTAL_ALIGNMENT_LEFT,-1,84,Color("f7f4ee"))
		canvas.draw_string(font,Vector2(74,420),"ESC  RESUME     ENTER / SPACE  SKIP",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("d9d2e5"))
	elif t<TITLE_AT and (t<3.2 or replay):
		canvas.draw_string(font,Vector2(1000,704),"ENTER / SPACE  SKIP",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("d9d2e5",.9 if t<2.8 or replay else (3.2-t)/.4*.9))

func _draw_radial(canvas:Control,strength:float,t:float) -> void:
	if strength<.03:return
	var centre:=Vector2(640,360)
	for i in 34:
		var angle:float=i*TAU/34.0+.05*sin(i*7.1)
		var direction:=Vector2(cos(angle),sin(angle))
		var phase:float=fposmod(t*2.6+i*.273,1.0)
		var inner:float=lerpf(300,640,phase)
		var tangent:Vector2=direction.orthogonal()*(2.0+i%4)*strength
		var tip:Vector2=centre+direction*Vector2(inner,inner*.62)
		var outer:Vector2=centre+direction*Vector2(inner+260,inner*.62+190)
		var color:=Color("fff6fb") if i%3==0 else Color("140c1c")
		color.a=(.3+phase*.45)*strength
		canvas.draw_colored_polygon(PackedVector2Array([tip,outer-tangent*2.0,outer+tangent*2.0]),color)

func _draw_side(canvas:Control,strength:float,t:float) -> void:
	if strength<.03:return
	for i in 22:
		var y:float=70.0+fposmod(i*97.3,580.0)
		var length:float=180.0+fposmod(i*53.7,360.0)
		var x:float=fposmod(i*211.0-t*2600.0,1280.0+length)-length
		var color:=Color("fff6fb") if i%3 else Color("140c1c")
		color.a=.55*strength
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(x,y),Vector2(x+length,y-1.5-i%3),Vector2(x+length,y+1.5+i%3)]),color)

func _burst(canvas:Control,at:Vector2,radius:float,rays:int,color:Color,spin:=0.0) -> void:
	if at.x<-500:return
	for i in rays:
		var angle:float=i*TAU/rays+spin
		var direction:=Vector2(cos(angle),sin(angle))
		var long:float=radius*(1.0 if i%2==0 else .55)
		canvas.draw_colored_polygon(PackedVector2Array([at+direction*radius*.18,at+direction*long+direction.orthogonal()*radius*.05,at+direction*long-direction.orthogonal()*radius*.05]),color)

func _word(canvas:Control,text:String,at:Vector2,size:int,color:Color,angle:float,alpha:float) -> void:
	var bold:Font=session.hud.bold
	canvas.draw_set_transform(at*canvas.size/Vector2(1280,720),angle,canvas.size/Vector2(1280,720))
	canvas.draw_string(bold,Vector2(5,6),text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color("120c1a",alpha))
	canvas.draw_string(bold,Vector2.ZERO,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color(color,alpha))
	canvas.draw_set_transform(Vector2.ZERO,0,canvas.size/Vector2(1280,720))

func _draw_accents(canvas:Control,t:float) -> void:
	# Comic accents pinned to the action, each a few frames long.
	if t>=3.0 and t<4.1:
		var spark:float=fposmod(t*4.5,1.0)
		if spark<.3:_burst(canvas,project(Vector3(-3.72,.7,-3.2)),30.0+spark*90.0,8,Color("fff3a8",1.0-spark*2.5),t*3.0)
	if t>=4.1 and t<5.0:
		var at:Vector2=project(Vector3(1.6,.6,-2.3))
		if at.x>-500:
			for i in 3:
				var y:float=at.y-30.0+i*26.0
				var points:=PackedVector2Array()
				for k in 7:points.append(Vector2(at.x+40.0+k*22.0,y+(10.0 if (k+int(t*20.0)+i)%2==0 else -10.0)))
				canvas.draw_polyline(points,Color("27e6ee"),5.0)
	for hit in [[6.55,Vector3(.12,.02,-1.6),"DOM",Color("fff3a8")],[8.0,Stage.TABLE+Vector3(0,.1,0),"BAM!",Color("ff2789")],[13.1,Vector3(.2,.9,5.4),"KLAK",Color("fff3a8")]]:
		var dt:float=t-hit[0]
		if dt<0 or dt>.34:continue
		var at:Vector2=project(hit[1])
		_burst(canvas,at,90.0+dt*520.0,12,Color("fff6fb",maxf(0,1.0-dt*3.2)),hit[0])
		_word(canvas,hit[2],Vector2(clampf(at.x+60,80,900),clampf(at.y-90,150,560)),88,hit[3],-.12,minf(1.0,(.34-dt)*8.0))
	for click in [9.15,9.45]:
		var dt:float=t-click
		if dt>=0 and dt<.2:
			var side:=-.45 if click<9.3 else .45
			_burst(canvas,project(Stage.TABLE+Vector3(side,.16,-.42)),26.0+dt*200.0,6,Color("fff6fb",1.0-dt*5.0),click)
	if t>=12.0 and t<12.8:
		_word(canvas,"SKRRRT",Vector2(120+sin(t*60.0)*4.0,250),70,Color("fff3a8"),-.08,minf(1.0,(12.8-t)*6.0)*seg(t,12.25,12.35))
	for stomp in [13.55,13.85]:
		var dt:float=t-stomp
		if dt>=0 and dt<.18:_burst(canvas,project(Vector3(.1,.02,4.2)),60.0+dt*500.0,10,Color("fff6fb",1.0-dt*5.5),stomp)
	if t>=14.55 and t<14.95 and suits.size()>0:
		# Glint across the leader's sunglasses.
		var k:=sin(seg(t,14.55,14.95)*PI)
		var at:Vector2=project(suits[0].point("Head")-ORIGIN+Vector3(.07,.04,-.12))
		_burst(canvas,at,70.0*k,4,Color("ffffff",k),PI*.25)
		_burst(canvas,at,34.0*k,4,Color("27e6ee",k),0.0)

func _draw_slam(canvas:Control,t:float) -> void:
	# One held impact frame on black before the title lands.
	var centre:=Vector2(640,360)
	_burst(canvas,centre,720.0,26,Color("f5129a"),.11)
	_burst(canvas,centre,520.0,18,Color("fff6fb"),.37)
	_burst(canvas,centre,210.0,12,Color("0b0910"),.2)
	_word(canvas,"KRAK!",Vector2(400,420),150,Color("fff6fb"),-.1,1.0)

func _draw_title(canvas:Control,t:float,reduced:bool) -> void:
	var land:=1.0 if reduced else seg(t,TITLE_AT+.06,TITLE_AT+.3)
	var sweep:=1.0-pow(1.0-land,3.0)
	# Cyan slash under the wordmark, wiping in from the left.
	var a:=Vector2(250,268);var b:=Vector2(250+820*sweep,222)
	canvas.draw_colored_polygon(PackedVector2Array([a+Vector2(0,-10),b+Vector2(0,-22),b+Vector2(-18,4),a+Vector2(-30,18)]),Color("27e6ee"))
	if not reduced and t<TITLE_AT+.3:
		_burst(canvas,Vector2(420,170),900.0*(1.0-land*.4),20,Color("fff6fb",(1.0-land)*.8),.3)
