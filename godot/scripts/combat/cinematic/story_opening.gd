extends Node3D
## Boot story opening: 15 seconds, follows the reference video's beats, real-time 3D with the roster models.
## One stateless authored timeline (sample(t) is repeatable), its own lens and score.
## Owns the session camera only while running; clear() restores everything it touched.
## Presentation only: no simulation, XP or combat state is read or written.
const Stage=preload("res://scripts/combat/story_opening/stage.gd")
const Actor=preload("res://scripts/combat/story_opening/actor.gd")
## The opening ends on the lid slam's black frame and cuts straight into the main menu (which carries the AFTERHOURS title itself).
## Real running time. The shots below are authored on the tighter edit timeline; WARP stretches it
## (slower holds on the case, the manifest and ZIP's face) so the cuts land on the music's own beats.
const DURATION:=16.12
## [real seconds, authored seconds] knots; after the last knot the two clocks run 3.0 s apart.
const WARP:=[[0.0,0.0],[1.5,1.3],[3.0,2.6],[6.0,4.5],[8.0,5.0]]
const WARP_TAIL:=3.0
const AUTHORED_END:=13.12
## Shot starts, then the end. Each shot is one beat of the reference video.
const CUTS:=[0.0,1.3,2.6,4.5,5.0,6.75,9.0,12.0,13.0,13.12]  # authored time
const SHOTS:=["BENCH","UNLATCH","MANIFEST","ZIP LOOKS UP","COLLECTORS ARRIVE","FROM THE CASE","HOLD","BENCH AGAIN","LID SLAM"]
const ORIGIN:=Vector3(2400,0,0)
const TITLE_AT:=13.1
const SLAM_AT:=13.0
const MUSIC_CUT:=6.75
## The menu track fades back in here, under the score's sign-off bar.
const MENU_MUSIC_AT:=13.1
## [time, strength] camera trauma. Mirrors the cue sheet in audio/story_opening/cues.json.
const IMPACTS:=[[1.3,.3],[1.95,.14],[2.25,.14],[2.5,.22],[5.0,.55],[10.55,.4],[10.85,.4],[11.2,.18],[13.0,1.3]]
const SUBTITLES:=[
	{"from":1.4,"to":2.3,"who":"RIVET","color":Color("ff8a1f"),"zh":"「吓！？」","en":"\"Huh?!\""},
	{"from":2.75,"to":4.3,"who":"LOOP","color":Color("c4ff00"),"zh":"「……我買音響喎。」","en":"\"...I ordered speakers.\""},
	{"from":6.95,"to":8.0,"who":"LOOP","color":Color("c4ff00"),"zh":"「開工？！」","en":"\"Work?!\""},
	{"from":8.05,"to":9.0,"who":"ZIP","color":Color("00e9ef"),"zh":"「退貨。」","en":"\"Return to sender.\""}]
## Where the collectors stop in the street, then where they step to later.
const SUIT_MARKS:=[Vector3(.1,0,4.1),Vector3(-1.5,0,4.45),Vector3(1.7,0,4.45)]
const SUIT_STEP:=Vector3(0,0,-1.0)
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
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color("9a86b4");environment.ambient_light_energy=.62

func advance(delta:float) -> void:
	if not running:return
	_sync_audio()
	if paused:return
	if scrub:sample(age);return
	age+=maxf(0.0,delta)
	if age>=DURATION:finish(false,true);return
	sample(age)

func finish(skipped:bool,let_score_ring:=false) -> void:
	if not running:return
	finished_count+=1
	if not seen:mark_seen()
	clear(let_score_ring)
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

func clear(let_score_ring:=false) -> void:
	var was_running:=running
	running=false;paused=false
	if is_instance_valid(score):
		score.stream_paused=false
		# On a natural end the title hit and second drop ring on under the menu.
		if not let_score_ring:score.stop()
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
	var silent:=authored(age)<MENU_MUSIC_AT
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

static func authored(real:float) -> float:
	for i in WARP.size()-1:
		if real<WARP[i+1][0]:return lerpf(WARP[i][1],WARP[i+1][1],(real-WARP[i][0])/(WARP[i+1][0]-WARP[i][0]))
	return real-WARP_TAIL

static func real_time(auth:float) -> float:
	for i in WARP.size()-1:
		if auth<WARP[i+1][1]:return lerpf(WARP[i][0],WARP[i+1][0],(auth-WARP[i][1])/(WARP[i+1][1]-WARP[i][1]))
	return auth+WARP_TAIL

func shot_at(t:float) -> int:
	for i in CUTS.size()-1:
		if t<CUTS[i+1]:return i
	return CUTS.size()-2

func trauma_at(t:float) -> float:
	var total:=0.0
	for hit in IMPACTS:
		var dt:float=t-hit[0]
		if dt>=0 and dt<.6:total+=hit[1]*exp(-dt*8.5)
	return minf(total,1.4)

func sample(real:float) -> void:
	age=real
	var t:=authored(real);shot=shot_at(t)
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
	var zip_head:Vector3=cast[0].point("Head")-ORIGIN
	if t<1.3:
		# Behind the bench: ZIP waits in the doorway light and the case slides in from the left.
		var u:=ease_io(seg(t,0.0,1.3))
		return {"at":Vector3(.4,1.3,-7.7).lerp(Vector3(.36,1.22,-6.5),u),"look":Vector3(.3,1.4,-3.0),"fov":lerpf(68,52,u),"roll":-1.0,"fisheye":.14,"shake":.04}
	if t<2.6:
		# Close on the case front: RIVET's gloves work the latches.
		var u1:=seg(t,1.3,2.6)
		return {"at":table+Vector3(.2,.6,-1.5).lerp(Vector3(.12,.52,-1.15),u1),"look":table+Vector3(.0,.2,.0),"fov":44.0,"roll":-2.0,"fisheye":.1,"shake":.035}
	if t<4.5:
		# Overhead on the open case: two guns, the silencer, the manifest.
		var u2:=seg(t,2.6,4.5)
		return {"at":table+Vector3(.2,lerpf(1.28,1.12,ease_io(u2)),0),"look":table+Vector3(.12,.2,0),"up":Vector3(1,0,0),"fov":56,"fisheye":.18,"vignette":.4}
	if t<5.0:
		# ZIP's face, tilted, eyes already on the door.
		var u3:=ease_io(seg(t,4.5,5.0))
		return {"at":zip_head+Vector3(.42,.06,-1.2).lerp(Vector3(.38,.05,-1.1),u3),"look":zip_head+Vector3(-.1,-.04,0),"fov":38.0,"roll":-9.0,"fisheye":.1,"blur":.012,"shake":.03}
	if t<MUSIC_CUT:
		# Over ZIP's shoulder: three collectors walk up the street.
		var u4:=seg(t,5.0,MUSIC_CUT)
		return {"at":Vector3(-.15,1.5,-1.05).lerp(Vector3(-.12,1.46,-.75),u4),"look":Vector3(.15,1.25,5.0),"fov":52.0,"roll":-1.0,"fisheye":.12,"shake":.05}
	if t<9.0:
		# Cut to the case: the open lid at the edge, ZIP's back, the collectors framed in the door.
		var u5:=seg(t,MUSIC_CUT,9.0)
		return {"at":table+Vector3(.04,.34,-.62).lerp(Vector3(.04,.32,-.74),u5),"look":Vector3(-.1,1.25,3.9),"fov":lerpf(66,60,u5),"roll":-2.0,"fisheye":.22,"vignette":.5,"shake":.01}
	if t<10.3:
		# Ground-level from the doorway: three suits hold the street.
		var u6:=seg(t,9.0,10.3)
		return {"at":Vector3(-2.6,.5,.4).lerp(Vector3(-2.1,.45,.5),u6),"look":Vector3(.3,1.0,3.9),"fov":58.0,"roll":4.0,"fisheye":.3,"shake":.04}
	if t<11.0:
		# Low on the polished shoes, in step.
		var u7:=seg(t,10.3,11.0)
		return {"at":Vector3(.5,.1,1.0+u7*.12),"look":Vector3(.1,.42,3.0),"fov":76,"roll":-4.0,"fisheye":.7,"chroma":.004,"shake":.07}
	if t<12.0:
		# Push in on the leader's sunglasses while the glove is pulled tight.
		var u8:=ease_io(seg(t,11.0,12.0))
		var head:Vector3=suits[0].point("Head")-ORIGIN+Vector3(0,.1,0)
		return {"at":Vector3(.75,1.25,.4).lerp(head+Vector3(.16,-.06,-.82),u8),"look":head,"fov":lerpf(52,34,u8),"roll":lerpf(6,0,u8),"fisheye":lerpf(.3,.5,u8),"blur":u8*.018,"radial":u8*.5,"shake":.03}
	if t<12.55:
		# Back at the bench: the case, ZIP's back and the collectors in the door, closing in.
		var u9:=ease_io(seg(t,12.0,12.55))
		return {"at":Vector3(1.5,1.78,-7.5).lerp(Vector3(1.3,1.72,-7.0),u9),"look":Vector3(-.1,1.25,3.6),"fov":lerpf(56,34,u9),"roll":-3.0,"fisheye":.15,"blur":sin(u9*PI)*.04,"radial":sin(u9*PI)*.7}
	if t<TITLE_AT:
		# Above the case as the lid comes down on the wordmark.
		var look:Vector3=stage.case_root.global_position-ORIGIN+Vector3(-.1,.28,0)
		return {"at":table+Vector3(1.05,1.02,-.28),"look":look,"fov":66,"roll":3.0,"fisheye":.5,"chroma":.006,"shake":.02}
	# Title: behind the four on the ledge, city in ink beyond.
	var title_progress:=seg(t,TITLE_AT,DURATION)
	return {"at":Vector3(.9,27.3,-9.7+title_progress*.35),"look":Vector3(-.35,28.7+title_progress*.08,10),"fov":40,"roll":-1.5,"fisheye":.1,"ink":1.0,"vignette":.0,"shake":.1}

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
		flash=maxf(maxf(0,1-absf(t-5.01)/.07)*.3,maxf(0,1-(t-TITLE_AT)/.26) if t>=TITLE_AT else 0.0)
		if t>=MUSIC_CUT and t<MUSIC_CUT+.08:flash=maxf(flash,.5)
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
	for actor in cast:
		actor.visible=true;actor.visual.set_neon_silhouette(title)
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
	else:
		hush.visible=false
		rivet.visible=t<2.6
		loop.visible=(t>=2.6 and t<4.5) or (t>=5.0 and t<MUSIC_CUT)
		# ZIP: behind the bench (to 5.0), at the door (to the cut), then beside the open case.
		if t<5.0:
			zip.place(Vector3(table.x,0,table.z+1.0),180.0)
			zip.clip("Idle_Loop",t*.8)
			_arms_down(zip)
			var dip:=ease_io(seg(t,1.0,1.6))*(1.0-seg(t,3.9,4.4))
			_lean(zip,.35*dip)
			zip.twist("Head",Vector3.UP,0.0)
			if t>=4.4:
				# Eyes up and to the door: the head swings aside on the cut-in.
				zip.twist("Head",Vector3.UP,-.9*ease_io(seg(t,4.4,4.65)))
			zip.finish(0.0)
		elif t<MUSIC_CUT:
			zip.place(Vector3(.55,0,-.1),0.0)
			zip.clip("Idle_Loop",t*.8)
			_arms_down(zip)
			zip.finish(0.0)
		else:
			zip.place(Vector3(table.x+.9,0,-2.7) if t<12.0 else Vector3(table.x+.3,0,table.z+1.0),0.0)
			zip.clip("Idle_Loop",t*.6)
			_arms_down(zip)
			if t<12.55:
				# ZIP turns his head to the case on his own line.
				zip.twist("Head",Vector3.UP,.5*ease_io(seg(t,8.0,8.5)))
			else:
				# Hand on the lid, driving it shut.
				var grip:Vector3=stage.case_lid.to_global(Vector3(-.12,.14,-.62))
				_lean(zip,.75)
				zip.reach("Right",grip,grip+Vector3(-.6,.4,.5))
			zip.finish(0.0)
		# RIVET at the near end of the bench: gloves on the latches.
		if rivet.visible:
			rivet.place(Vector3(table.x+(2.0 if t<1.3 else 1.2),0,table.z-.62),-62.0)
			rivet.clip("Idle_Loop",t*.7+.4)
			_arms_down(rivet)
			_lean(rivet,.5)
			var latch_b:Vector3=w(table+Vector3(.45,.2,-.46))
			var corner:Vector3=w(table+Vector3(.72,.24,-.4))
			if t<1.0:
				rivet.reach("Right",w(table+Vector3(1.0,.25,-.55)),w(table+Vector3(1.5,.6,-1.5)))
				rivet.reach("Left",corner,w(table+Vector3(1.5,.3,-1.5)))
			elif t<2.6:
				var tug_b:=sin(seg(t,2.05,2.25)*PI)*.05
				rivet.reach("Right",latch_b+Vector3(0,tug_b,-.04),latch_b+Vector3(.4,.5,-.9))
				rivet.reach("Left",corner+Vector3(0,sin(seg(t,1.7,1.95)*PI)*.04,0),corner+Vector3(.4,.4,-.9))
			rivet.finish(0.0)
		# LOOP at the far end: a finger on the manifest.
		if loop.visible:
			if t<MUSIC_CUT and t>=5.0:
				# Over ZIP's shoulder, bottom of frame: green hair and a shoulder.
				loop.place(Vector3(-.6,0,-.4),0.0)
				loop.clip("Idle_Loop",t*.7)
				_arms_down(loop)
			else:
				loop.place(Vector3(table.x+.95,0,table.z+1.0),180.0)
				loop.clip("Idle_Loop",t*.7+1.1)
				_arms_down(loop)
				_lean(loop,.55)
				var rest:Vector3=w(table+Vector3(.4,.3,1.0))
				var page:Vector3=stage.case_root.to_global(Vector3(.52,.22,.0))
				var point:=ease_io(seg(t,2.9,3.3))*(1.0-ease_io(seg(t,3.55,3.8)))
				var pull:=ease_io(seg(t,3.75,4.2))
				var hand:Vector3=rest.lerp(page+Vector3(.05,.04,0),maxf(point,pull))
				hand+=Vector3(0,0,.12*pull)
				if t>=2.7:loop.reach("Left",hand,hand+Vector3(.5,.5,.5))
			loop.finish(0.0)
	# Collectors.
	var walk_from:=3.6;var walk_to:=6.0
	for i in 3:
		var suit:Node3D=suits[i];suit.visible=t>=walk_from and t<TITLE_AT
		if not suit.visible:continue
		var mark:Vector3=SUIT_MARKS[i]
		var step:=seg(t,walk_from,walk_to)
		var from:=Vector3(mark.x,0,mark.z+4.8)
		var walking:=step<1.0
		var advance:=.5*ease_io(seg(t,10.45,10.7))+.5*ease_io(seg(t,10.78,11.0))
		if advance>0 and advance<1.0:walking=true
		suit.place(from.lerp(mark,step)+SUIT_STEP*advance,180.0)
		if walking:suit.clip("Walk_Loop",(t-walk_from)*1.05,1.6)
		else:suit.clip("Idle_Loop",.3+t*.25)
		_arms_down(suit)
		if i==0 and t>=5.9 and t<TITLE_AT:
			# Pull the left glove tight across the chest.
			var raise:=ease_io(seg(t,5.9,6.2))
			var chest:Vector3=suit.point("Spine2") if suit.visual.motions.bone_index("Spine2")>=0 else suit.point("Hips")+Vector3.UP*.5
			var wrist:Vector3=chest+suit.forward()*.34+Vector3.DOWN*.08+suit.right()*-.06
			var arm:Vector3=suit.point("LeftArm")
			suit.reach("Left",arm.lerp(wrist,raise)+Vector3.DOWN*(1.0-raise)*.5,wrist+suit.right()*-.7+Vector3.DOWN*.5)
			var tug:=sin(seg(t,11.2,11.5)*PI)*.07
			suit.reach("Right",(suit.point("RightArm")+Vector3.DOWN*.5).lerp(wrist+suit.right()*(.1+tug)+Vector3.DOWN*.02,raise),wrist+suit.right()*.7+Vector3.DOWN*.5)
		suit.finish(-.1)

func _props_at(t:float) -> void:
	var table:Vector3=Stage.TABLE
	var case:Node3D=stage.case_root
	case.visible=t>=.72 and t<TITLE_AT
	# The case slides in from the left and lands with a hop. On the cut to the overhead it turns on the bench so the open lid stands on the side, clear of ZIP.
	var slide:=ease_io(seg(t,.72,1.3))
	var hop:=maxf(0.0,sin(seg(t,1.3,1.46)*PI))*.03
	var yaw:=0.0 if t<2.6 else -90.0
	case.transform=Transform3D(Basis(Vector3.UP,deg_to_rad(yaw)),table+Vector3((1.0-slide)*1.7,hop,0))
	var latch:=0.0
	if t>=1.85:latch=.5*seg(t,1.85,1.95)
	if t>=2.15:latch=.5+.5*seg(t,2.15,2.25)
	var open:=0.0
	if t>=2.4:open=ease_io(seg(t,2.4,2.62))
	if t>=12.55:open=1.0-pow(seg(t,12.68,SLAM_AT),2.6)
	var glow:=0.0
	if t>=2.45 and t<MUSIC_CUT:glow=lerpf(.5,.1,seg(t,2.45,3.4))
	elif t>=MUSIC_CUT and t<9.0:glow=lerpf(.3,.06,seg(t,MUSIC_CUT,8.0))
	stage.pose_case(open,latch,glow)
	stage.case_print.visible=t>=12.4
	stage.pose_table(seg(t,1.3,1.62) if t>=1.3 and t<1.62 else 0.0)
	# Fluorescent tubes stutter in the silence after the music is cut.
	var level:=1.0
	if t>=MUSIC_CUT and t<9.0 and not session.reduced_effects:
		level=.82+.18*signf(sin(t*31.0)+sin(t*47.0)+.9)
		if absf(t-7.05)<.05 or absf(t-8.2)<.04:level=.35
	stage.set_tube_flicker(level)
	stage.ledge.visible=true

func _puffs_at(t:float,reduced:bool) -> void:
	# [time, centre, count, spread, life, size]; deterministic, capped at the pool.
	var bursts:=[[.95,Stage.TABLE+Vector3(.7,.0,-.2),5,.7,.45,.1],[1.3,Stage.TABLE+Vector3(0,.0,-.2),7,.9,.5,.1],[10.55,Vector3(.1,.02,3.2),5,1.4,.5,.2],[10.85,Vector3(.1,.02,2.95),5,1.4,.5,.2]]
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
	var t:=authored(age);var reduced:bool=session.reduced_effects
	var ink:=Color("0b0910");var bold:Font=session.hud.bold;var font:Font=session.hud.font
	if not reduced:
		_draw_radial(canvas,speed_radial,t)
		_draw_side(canvas,speed_side,t)
		_draw_accents(canvas,t)
	if t>=TITLE_AT:_draw_title(canvas,t,reduced)
	else:
		canvas.draw_rect(Rect2(0,0,1280,58),ink);canvas.draw_rect(Rect2(0,662,1280,58),ink)
	if t>=SLAM_AT and t<TITLE_AT and not reduced:_draw_slam(canvas,t)
	for line in SUBTITLES:
		if t<line.from or t>=line.to:continue
		# Reference style: small white speaker name over a centred line, no box. Cantonese is authored; English rides underneath.
		var zh:bool=subtitle_font!=null
		var text:String=line.zh if zh else line.en
		var face:Font=subtitle_font if zh else font
		var size:=34 if zh else 28
		var width:float=face.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
		var name_width:float=bold.get_string_size(line.who,HORIZONTAL_ALIGNMENT_LEFT,-1,24).x
		for shadow in [Vector2(2,2),Vector2.ZERO]:
			var col:=Color(ink,.9) if shadow!=Vector2.ZERO else Color("f7f4ee")
			canvas.draw_string(bold,Vector2(640-name_width*.5,598)+shadow,line.who,HORIZONTAL_ALIGNMENT_LEFT,-1,24,col)
			canvas.draw_string(face,Vector2(640-width*.5,636)+shadow,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,col if shadow!=Vector2.ZERO else line.color.lerp(Color("f7f4ee"),.7))
		if zh:canvas.draw_string(font,Vector2(640-font.get_string_size(line.en,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x*.5,672),line.en,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("bcb6c6"))
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
	# The glint reaches zero at its endpoints; skip collapsed/subpixel rays.
	# Submit each triangle directly: thin rays at HUD coordinates can also
	# lose precision in the general polygon triangulator.
	if at.x<-500 or radius<1.0 or rays<=0 or color.a<=0.0:return
	for i in rays:
		var angle:float=i*TAU/rays+spin
		var direction:=Vector2(cos(angle),sin(angle))
		var long:float=radius*(1.0 if i%2==0 else .55)
		canvas.draw_primitive(PackedVector2Array([at+direction*radius*.18,at+direction*long+direction.orthogonal()*radius*.05,at+direction*long-direction.orthogonal()*radius*.05]),PackedColorArray([color]),PackedVector2Array())

func _draw_accents(canvas:Control,t:float) -> void:
	# Comic accents pinned to the action, each a few frames long.
	for hit in [[1.3,Stage.TABLE+Vector3(0,.1,0)],[5.0,Vector3(.1,1.0,4.3)]]:
		var dt:float=t-hit[0]
		if dt<0 or dt>.34:continue
		var at:Vector2=project(hit[1])
		_burst(canvas,at,90.0+dt*520.0,12,Color("fff6fb",maxf(0,1.0-dt*3.2)),hit[0])
	for click in [1.95,2.25]:
		var dt:float=t-click
		if dt>=0 and dt<.2:
			var side:=-.45 if click<2.1 else .45
			_burst(canvas,project(Stage.TABLE+Vector3(side,.16,-.42)),26.0+dt*200.0,6,Color("fff6fb",1.0-dt*5.0),click)
	for stomp in [10.55,10.85]:
		var dt:float=t-stomp
		if dt>=0 and dt<.18:_burst(canvas,project(Vector3(.1,.02,3.1)),60.0+dt*500.0,10,Color("fff6fb",1.0-dt*5.5),stomp)
	if t>=11.55 and t<11.95 and suits.size()>0:
		# Glint across the leader's sunglasses.
		var k:=sin(seg(t,11.55,11.95)*PI)
		var at:Vector2=project(suits[0].point("Head")-ORIGIN+Vector3(.07,.04,-.12))
		_burst(canvas,at,70.0*k,4,Color("ffffff",k),PI*.25)
		_burst(canvas,at,34.0*k,4,Color("27e6ee",k),0.0)

func _draw_slam(canvas:Control,_t:float) -> void:
	# One held impact frame on black before the title lands.
	var centre:=Vector2(640,360)
	_burst(canvas,centre,720.0,26,Color("f5129a"),.11)
	_burst(canvas,centre,520.0,18,Color("fff6fb"),.37)
	_burst(canvas,centre,210.0,12,Color("0b0910"),.2)

func _draw_title(canvas:Control,t:float,reduced:bool) -> void:
	var land:=1.0 if reduced else seg(t,TITLE_AT+.06,TITLE_AT+.3)
	var sweep:=1.0-pow(1.0-land,3.0)
	# Cyan slash under the wordmark, wiping in from the left.
	var a:=Vector2(250,268);var b:=Vector2(250+820*sweep,222)
	canvas.draw_colored_polygon(PackedVector2Array([a+Vector2(0,-10),b+Vector2(0,-22),b+Vector2(-18,4),a+Vector2(-30,18)]),Color("27e6ee"))
	if not reduced and t<TITLE_AT+.3:
		_burst(canvas,Vector2(420,170),900.0*(1.0-land*.4),20,Color("fff6fb",(1.0-land)*.8),.3)
