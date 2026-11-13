extends Node3D
## Presentation only: pooled opaque ink smoke, real bone trails and contact accents.
const Recipes=preload("res://scripts/combat/ink_fx/fx_recipes.gd")
const LIMIT=36
const DECOR_LIMIT=18
var pool:Array[Dictionary]=[]
var tracking:Dictionary={}
var traces:Array[Dictionary]=[]
var serial:=0
var spawned:=0
var dropped:=0
var peak:=0
var contact_age:=1.0
var contact_strength:=0.0
var contact_axis:=Vector2.RIGHT
var contact_at:=Vector3.ZERO
var contact_cooldown:=0.0
const PUFF_LIGHT:=Color(.80,.76,.88)
const PUFF_DARK:=Color(.22,.20,.30)
var puff_textures:Array[ImageTexture]=[]
const ACCENTS:=[Color("00d6d8"),Color("ff921c"),Color("ff459d"),Color("b8ff00"),Color("a888ff")]
func _ready() -> void:
    name="AuthoredInkFX"
    # Textured dust puffs (CC0 Kenney smoke particle pack, see assets/vfx/SOURCES.md).
    var atlas:Image=(load("res://assets/vfx/puffs.png") as Texture2D).get_image()
    for n in 6:
        @warning_ignore("integer_division")
        puff_textures.append(ImageTexture.create_from_image(atlas.get_region(Rect2i((n%3)*48,(n/3)*48,48,48))))
    var quad:=QuadMesh.new();quad.size=Vector2(2,1);quad.center_offset=Vector3(0,.5,0)
    for i in LIMIT:
        var holder:=Node3D.new();add_child(holder)
        var body:=MeshInstance3D.new();holder.add_child(body);body.mesh=quad
        body.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        var mat:=_material(Color.WHITE);mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
        mat.albedo_texture=puff_textures[i%6];mat.disable_receive_shadows=true
        mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST;mat.alpha_scissor_threshold=.5;mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
        body.material_override=mat
        holder.hide()
        pool.append({"node":holder,"body":body,"mat":mat,"tint":PUFF_LIGHT,"age":1.0,"life":.2,"rank":0,"at":Vector3.ZERO,"velocity":Vector3.ZERO,"size":Vector2.ONE,"variant":i%3,"roll":0.0,"cel":-1})
func _material(color:Color) -> StandardMaterial3D:
    var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color=color;mat.cull_mode=BaseMaterial3D.CULL_DISABLED
    return mat
func clear() -> void:
    for item in pool:item.age=item.life;item.node.hide()
    RenderingServer.global_shader_parameter_set("ink_fx_focus",0.0)
    tracking.clear();traces.clear();contact_age=1.0;contact_strength=0.0;contact_cooldown=0.0
func active_count(decor_only:=false) -> int:
    var count:=0
    for item in pool:
        if item.age<item.life and (not decor_only or item.rank==0):count+=1
    return count
func emit_puff(kind:String,at:Vector3,direction:float,rank:=0,character:=0,gain:=1.0,tint_override:=Color.TRANSPARENT) -> void:
    if not Recipes.RECIPES.has(kind):return
    if rank==0 and active_count(true)>=DECOR_LIMIT:dropped+=1;return
    var slot:Dictionary={}
    for item in pool:
        if item.age>=item.life:slot=item;break
    if slot.is_empty():
        for item in pool:
            if item.rank<rank and (slot.is_empty() or item.age/item.life>slot.age/slot.life):slot=item
    if slot.is_empty():dropped+=1;return
    var spec:Vector3=Recipes.RECIPES[kind]
    serial+=1;spawned+=1
    slot.age=0.0;slot.life=spec.z*(.92+float(serial%3)*.08)
    slot.at=at;slot.rank=rank;slot.variant=serial%3;slot.cel=-1
    slot.size=Vector2(spec.x,spec.y)*gain
    slot.velocity=Vector3(direction*(.30 if kind in ["step","run","jump"] else .9),.35 if kind in ["wake","heavy","launch"] else .12,0)
    slot.tint=PUFF_DARK if kind=="wake" and serial%3==0 else (ACCENTS[clampi(character,0,4)] if kind=="parry" else PUFF_LIGHT)
    if tint_override.a>0:slot.tint=tint_override
    slot.roll=float(serial%7-3)*.28
    slot.mat.albedo_texture=puff_textures[serial%6]
    slot.node.show();peak=maxi(peak,active_count())
func ground(kind:String,at:Vector3,face:float,character:int,reduced:bool,tint_override:=Color.TRANSPARENT) -> void:
    if reduced:return
    var count:=1 if kind in ["step","run"] else (5 if kind=="slam" else 3)
    for i in count:
        var direction:float=-face if kind in ["dash","run","step"] else (-1.0 if i%2==0 else 1.0)
        var p:=at+Vector3(direction*float(i)*.11,.045,.12 if i%2==0 else -.12)
        emit_puff(kind,p,direction,1 if kind=="slam" else 0,character,1.0+float(i%2)*.12,tint_override)
func contact_point(session:Node,event:Dictionary) -> Vector2:
    var side:int=clampi(event.get("attacker",0),0,1)
    var target:int=clampi(event.get("target",1-side),0,1)
    var victim:Dictionary=session.sim.fighters[target]
    var attacker:Dictionary=session.sim.fighters[side]
    var visual:Node=session.fighters[side]
    var bone:String=Recipes.limb(event.get("move","jab"),visual.character_index,attacker)
    var at:Vector3=visual.fx_socket(bone)+Vector3(attacker.x-visual.position.x,attacker.y-visual.position.y,0)
    return Vector2(clampf(at.x,victim.x-.42,victim.x+.42),clampf(at.y,victim.y+.55,victim.y+session.fighters[target].model_scale*.86))
func on_event(session:Node,event:Dictionary) -> void:
    if session.reduced_effects:return
    var side:int=clampi(event.get("target",event.get("owner",0)),0,1)
    var f:Dictionary=session.sim.fighters[side]
    var character:int=session.fighters[side].character_index
    var at:=Vector3(f.x,.045,session.FIGHT_Z)
    if event.kind in ["dash","jump","land"]:
        if event.kind=="dash" and f.y>.04:
            emit_puff("wake",Vector3(f.x,f.y+.45,session.FIGHT_Z),-f.face,0,character,.65)
        else:ground(event.kind,at,signf(f.vx) if absf(f.vx)>.1 else f.face,character,false)
    elif event.kind in ["air_land","ground_bounce","slam"]:
        ground("slam" if event.kind!="air_land" or event.get("hard",false) else "land",at,f.face,character,false)
    elif event.kind=="wall_bounce":
        emit_puff("impact",Vector3(f.x,f.y+.8,session.FIGHT_Z-.1),-f.face,1,character)
    elif event.kind=="arena_bounce":
        if event.surface=="floor":ground("slam",Vector3(event.x,.045,session.FIGHT_Z),f.face,character,false)
    elif event.kind in ["hit","parry","guard_break"]:
        if event.kind=="hit":session.fighters[side].fx_flash_age=0.0
        var p:=contact_point(session,event)
        var axis:=Vector2(event.get("face",1.0),.85 if event.get("move","")=="launcher" else (-.6 if event.get("move","")=="meteor" else .10)).normalized()
        var strength:float=event.get("strength",.8)
        if contact_cooldown<=0 or strength>contact_strength:
            contact_at=Vector3(p.x,p.y,session.FIGHT_Z);contact_age=0;contact_strength=strength;contact_axis=axis;contact_cooldown=.075
        if event.kind=="hit" and strength>=.55:
            emit_puff("launch" if event.get("move","")=="launcher" else "heavy",Vector3(p.x,p.y,session.FIGHT_Z-.25),-axis.x,1,character,.7)
func advance(session:Node,delta:float) -> void:
    var paused:bool=session.screen in ["pause","help"]
    visible=session.screen in ["play","pause","help","result"] and not session.city_breaker.active() and not session.ability_draw.active()
    if paused:return
    var visuals:Array=session.fighters.duplicate()
    for visual in session.squad_visuals:
        if visual not in visuals:visuals.append(visual)
    for visual in visuals:visual.fx_advance_flash(delta,session.reduced_effects)
    if session.reduced_effects:
        for item in pool:item.age=item.life;item.node.hide()
        traces.clear();contact_age=1.0;contact_strength=0.0
    var rate:float=session.rhythm.view_speed() if session.screen=="play" else 1.0
    var dt:float=minf(delta,.05)*maxf(.15,rate)
    # Contact flash is a single wall-time accent. It never strobes during hitstop.
    contact_age+=minf(delta,.05);contact_cooldown=maxf(0,contact_cooldown-delta)
    var focus:float=0.0
    if session.screen=="play" and not session.reduced_effects and not session.round_theatre.hold_simulation():
        focus=.15+maxf(0,1.0-contact_age/.20)*minf(.50,contact_strength*.5)
    RenderingServer.global_shader_parameter_set("ink_fx_focus",focus)
    RenderingServer.global_shader_parameter_set("ink_fx_focus_at",Vector3((session.sim.fighters[0].x+session.sim.fighters[1].x)*.5,1,session.FIGHT_Z))
    for item in pool:
        if item.age>=item.life:continue
        item.age+=dt
        if item.age>=item.life:item.node.hide();continue
        var t:float=item.age/item.life
        item.node.position=item.at+item.velocity*item.age
        item.node.basis=session.camera.global_basis*Basis(Vector3.BACK,item.roll)
        # Cel style: pop in, hold at full opacity, then shrink away (no alpha fade).
        var grow:float=(.55+.8*(1.0-pow(1.0-t,2.0)))*(1.0-maxf(0.0,t-.55)/.45*.8)
        item.node.scale=Vector3(item.size.x*grow,item.size.x*grow*.9,1)
        item.mat.albedo_color=item.tint
    if session.screen!="play" or session.round_theatre.hold_simulation():return
    # Called after visual poses. Distances use actual movement, so render FPS and
    # hitstop cannot create extra footsteps, wakes, or ribbon samples.
    _actor(session,0,session.sim.fighters[0],session.fighters[0],delta)
    if session.sim.squad_enabled:
        for id in session.sim.squad_members.size():_actor(session,id+1,session.sim.squad_members[id],session.squad_visuals[id],delta)
    else:_actor(session,1,session.sim.fighters[1],session.fighters[1],delta)
    for trace in traces:trace.age+=delta*rate
    traces=traces.filter(func(t:Dictionary)->bool:return t.age<.14)
func _actor(session:Node,id:int,f:Dictionary,visual:Node,_delta:float) -> void:
    var pos:=Vector2(f.x,f.y)
    if not tracking.has(id):tracking[id]={"pos":pos,"stride":0.0,"foot":0,"vx":0.0,"wake":0.0,"serial":-1,"tip":Vector3.ZERO}
    var track:Dictionary=tracking[id]
    var moved:float=pos.distance_to(track.pos)
    var dx:float=pos.x-track.pos.x
    var old_vx:float=track.vx
    track.pos=pos;track.vx=f.vx
    if moved>2.0:track.stride=0.0;track.serial=-1;return
    if f.health<=0:track.stride=0.0;track.serial=-1;return
    if f.y<=.015 and f.state=="idle":
        if absf(dx)>.0001:
            track.stride+=absf(dx)
            if track.stride>=.72:
                track.stride=fmod(track.stride,.72);track.foot=1-track.foot
                var left:Vector3=visual.fx_socket("LeftFoot");var right:Vector3=visual.fx_socket("RightFoot")
                var foot:Vector3=left if left.y<right.y else right
                foot.y=.045;foot.z=clampf(foot.z,session.FIGHT_Z-.35,session.FIGHT_Z+.35)
                ground("run" if absf(f.vx)>3 else "step",foot,signf(dx),visual.character_index,session.reduced_effects)
                session.audio.play_sound("step",1.0+float(track.foot)*.035,-15 if id>1 else -12)
        if absf(old_vx)>3.0 and (absf(f.vx)<.2 or signf(old_vx)!=signf(f.vx)):
            ground("brake",Vector3(f.x,.045,session.FIGHT_Z),signf(old_vx),visual.character_index,session.reduced_effects)
    else:track.stride=0.0
    if not session.reduced_effects and f.state=="stun" and absf(f.vx)>5.5 and moved>.025:
        track.wake+=moved
        if track.wake>=.32:
            track.wake=fmod(track.wake,.32)
            emit_puff("wake",Vector3(f.x,f.y+.70,session.FIGHT_Z-.16),-signf(f.vx),0,visual.character_index,.8 if id>1 else 1.0)
    else:track.wake=0.0
    if f.character==0 and f.state=="attack" and f.move=="overdrive" and f.y<=.015 and not session.reduced_effects:
        var delivery_key:String=str(f.service.serial)+"/"+str(f.service.delivery_stage)
        var stride:int=floori(float(f.frame)/5.0) if f.frame<14 else -1
        var run_key:String=str(f.service.serial)+"/"+str(stride)
        if stride>=0 and track.get("delivery_run","")!=run_key:
            track["delivery_run"]=run_key
            ground("run",Vector3(f.x,.045,session.FIGHT_Z),f.face,0,false,Color("f7fff9"))
        if f.frame>=14 and track.get("delivery_key","")!=delivery_key:
            track["delivery_key"]=delivery_key
            ground("brake",Vector3(f.x,.045,session.FIGHT_Z),f.face,0,false,Color("f7fff9"))
    if f.character==0 and f.state=="attack" and f.move=="special" and f.y<=.015 and not session.reduced_effects:
        var zip_key:String=str(f.service.serial)+"/"+str(f.service.get("zip_second",false))
        if track.get("zip_key","")!=zip_key:
            track["zip_key"]=zip_key
            ground("brake" if f.service.zip_second else "dash",Vector3(f.x,.045,session.FIGHT_Z),f.face,0,false,Color("f7fff9"))
        var return_frame:int=session.sim.move_for(f,f.move).startup+8
        if f.frame>=return_frame and track.get("zip_plant",-1)!=f.service.serial:
            track["zip_plant"]=f.service.serial
            ground("land",Vector3(f.x,.045,session.FIGHT_Z),f.face,0,false,Color("f7fff9"))
    elif f.state!="attack":track["zip_key"]=""
    if session.reduced_effects or f.state!="attack":track.serial=-1;return
    var move:Dictionary=session.sim.move_for(f,f.move)
    var attack_serial:int=f.service.serial
    var tip:Vector3=visual.fx_socket(Recipes.limb(f.move,visual.character_index,f))
    if track.serial!=attack_serial:track.serial=attack_serial;track.tip=tip;return
    if f.frame>=move.startup-2 and f.frame<=move.startup+move.active and session.sim.hitstop==0:
        var last:Vector3=track.tip
        if tip.distance_to(last)>.025 and tip.distance_to(last)<2.8:
            if traces.size()>=32:traces.pop_front()
            traces.append({"a":last,"b":tip,"age":0.0,"color":session.neon_profile.accent(visual.character_index),"character":visual.character_index,"gain":.65 if id>1 else 1.0})
    track.tip=tip
func draw(canvas:Control,session:Node) -> void:
    if not visible or session.reduced_effects or session.screen not in ["play","pause","help"]:return
    var viewport:Vector2=session.get_viewport().get_visible_rect().size
    for trace in traces:
        var a:Vector2=session.camera.unproject_position(trace.a)*Vector2(1280,720)/viewport
        var b:Vector2=session.camera.unproject_position(trace.b)*Vector2(1280,720)/viewport
        var width:float=(1.0-trace.age/.14)*trace.gain*(8 if trace.character==1 else 4)
        var side:Vector2=(b-a).normalized().orthogonal()*width
        canvas.draw_colored_polygon(PackedVector2Array([a-side*.2,b-side,b+side,a+side*.2]),trace.color)
        if trace.age<.045:canvas.draw_line(a,b,Recipes.PAPER,1)
    if contact_age<.065 and session.screen=="play":
        var at:Vector2=session.camera.unproject_position(contact_at)*Vector2(1280,720)/viewport
        var axis:=Vector2(contact_axis.x,-contact_axis.y)
        var extent:float=8+contact_strength*10
        canvas.draw_line(at-axis*extent,at+axis*extent,Recipes.PAPER,3 if contact_age<.025 else 1)
func camera_kick() -> Vector2:
    if contact_age>.16:return Vector2.ZERO
    return Vector2(-contact_axis.x,contact_axis.y)*minf(.055,.025+contact_strength*.035)*exp(-contact_age*25.0)

func _exit_tree() -> void:
    RenderingServer.global_shader_parameter_set("ink_fx_focus",0.0)
