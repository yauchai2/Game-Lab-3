extends Node
## Owns the safe-city/one-encounter/return loop; standard modes never read its save.
var session:Node3D
var profile=preload("res://scripts/combat/city/city_profile.gd").new()
var hub:CanvasLayer
var active:=false
var selected_hero:=0
var settlement_done:=false
var last_result:=""
var dressing:Node3D
@export var save_path:="user://neon_lab/city_v1.json"

func setup(owner_session:Node3D) -> void:
    session=owner_session;profile.path=save_path;profile.load_data()
    hub=preload("res://scripts/combat/city/city_hub.gd").new();hub.campaign=self;add_child(hub)

func hero_id() -> int:
    return int(profile.data.run.hero) if not profile.data.run.is_empty() else selected_hero

func open_city() -> void:
    active=true
    if profile.data.run.is_empty():selected_hero=clampi(session.character_choices[0],0,3)
    show_city()

func show_city() -> void:
    if profile.data.run.is_empty():selected_hero=clampi(session.character_choices[0],0,3)
    session.return_to_title()
    active=true;session.screen="city";session.pending.clear();session.hud.visible=false
    hub.show_city()
    if profile.migration_notice!="":hub.notice=profile.migration_notice
    elif last_result!="":hub.notice=last_result
    session.audio.context="title"

func leave_city() -> void:
    hub.hide_city();active=false;session.hud.visible=true;session.return_to_title()

func depart() -> void:
    if profile.data.run.is_empty():
        if not profile.start_run(hero_id()):return
    if profile.data.run.boon_due or profile.error!="":return
    var before:Dictionary=profile.data.duplicate(true)
    profile.data.run["in_flight"]=true
    if not profile.commit(before):hub.refresh_header();return
    var room:=int(profile.data.run.room)
    hub.hide_city();session.hud.visible=true
    # start_story clears old modes first. Enable the campaign profile afterwards.
    session.set_character(0,hero_id());session.start_story()
    active=true
    var sim=session.sim
    sim.campaign_enabled=true;sim.campaign_skills=profile.data.skills.duplicate()
    sim.campaign_stats=profile.stats(hero_id());sim.campaign_room=room
    var challenge:bool=profile.data.run.get("mode","story")=="contract"
    sim.campaign_caption="ENCOUNTER %d / 18"%(room+1)
    sim.campaign_counter="%d/18"%(room+1)
    if challenge:
        var contract:Dictionary=profile.data.run.contract
        sim.campaign_stats.merge(profile.Contracts.tuning(contract),true)
        sim.campaign_tier=int(contract.tier)
        sim.campaign_captain=int(profile.data.run.wave)==int(contract.waves)-1
        sim.campaign_caption="T%d / WAVE %d OF %d"%[int(contract.tier),int(profile.data.run.wave)+1,int(contract.waves)]
        sim.campaign_counter="%d/%d"%[int(profile.data.run.wave)+1,int(contract.waves)]
        sim.wave_recipes=[profile.Contracts.recipe(contract,int(profile.data.run.wave))]
    else:sim.wave_recipes=[profile.recipe(room)]
    sim._load_wave(0,int(profile.data.run.hp),float(profile.data.run.meter)+float(sim.campaign_stats.entry))
    # Entry meter is awarded once per expedition, never again after reloading/re-entry.
    if profile.data.run.get("entered",false):sim.fighters[0].meter=float(profile.data.run.meter)
    else:
        before=profile.data.duplicate(true);profile.data.run["entered"]=true
        profile.data.run.meter=sim.fighters[0].meter
        if not profile.commit(before):show_city();return
    session._sync_story_visuals();session._present(0)
    settlement_done=false;last_result=""
    _build_dressing(room)
    session.hud.rebuild_menu()

func encounter_finished() -> bool:
    if not active or not session.sim.campaign_enabled:return false
    return session.sim.story_state in ["complete","failed"]

func result_text() -> String:
    return "ENCOUNTER CLEAR / RETURN TO SAFE BLOCK" if session.sim.story_state=="complete" else "EXPEDITION ENDED / BANKED LOOT KEPT"

func return_from_encounter() -> void:
    if not encounter_finished():return
    if not settlement_done:
        var won:bool=session.sim.story_state=="complete"
        var was_story:bool=profile.data.run.get("mode","story")=="story"
        var last_room:=int(profile.data.run.room)
        var hp:=int(session.sim.fighters[0].health);var meter:=float(session.sim.fighters[0].meter)
        if not profile.settle(won,hp,meter):
            session.hud.notice=profile.error;session.hud.notice_time=6;return
        settlement_done=true
        last_result="Encounter banked. Choose current at DEPART; new skills may be ready." if won else "Back home. Temporary current lost; permanent progress retained."
        if won and was_story and last_room==17:last_result="Tower captain defeated. The signal is back. All six districts can be replayed."
    show_city()

func clear_dressing() -> void:
    if is_instance_valid(dressing):
        dressing.get_parent().remove_child(dressing);dressing.queue_free()

func _build_dressing(room:int) -> void:
    clear_dressing();dressing=Node3D.new();session.add_child(dressing)
    var colors:=[Color("00cad7"),Color("bedb38"),Color("8078d0"),Color("d48641"),Color("c63b74"),Color("e5e0ef")]
    var sector:=mini(5,floori(float(room)/3.0));var tint:Color=colors[sector]
    for i in 8:
        var mesh:=MeshInstance3D.new();var shape:=BoxMesh.new()
        shape.size=Vector3(.9,.4+float((i+sector)%3)*.5,.8);mesh.mesh=shape
        var mat:=StandardMaterial3D.new();mat.albedo_color=tint.darkened(.35);mat.roughness=1;mesh.material_override=mat
        dressing.add_child(mesh);mesh.position=Vector3(-7+i*2,shape.size.y*.5,1.1)
    _district_set(sector,tint)
    var sign:=Label3D.new();sign.text=profile.DISTRICTS[sector];sign.position=Vector3(0,4.4,-.5)
    sign.font_size=60;sign.pixel_size=.012;sign.modulate=tint;sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED;dressing.add_child(sign)

func _prop(at:Vector3,extent:Vector3,tint:Color) -> void:
    var mesh:=MeshInstance3D.new();var shape:=BoxMesh.new();shape.size=extent;mesh.mesh=shape
    var mat:=StandardMaterial3D.new();mat.albedo_color=tint;mat.roughness=1;mesh.material_override=mat
    dressing.add_child(mesh);mesh.position=at

func _district_set(sector:int,tint:Color) -> void:
    match sector:
        0:
            for x in [-6.0,6.0]:
                _prop(Vector3(x,2.5,-.8),Vector3(.25,5,.25),tint.darkened(.4))
                _prop(Vector3(x,4.2,-.5),Vector3(1.8,.5,.3),tint)
            _prop(Vector3(0,5.0,-.8),Vector3(12,.15,.15),Color("1e2337"))
        1:
            for x in [-7.0,7.0]:
                _prop(Vector3(x,2,0),Vector3(.7,4,.9),tint.darkened(.4))
                for y in [1.0,2.0,3.0]:_prop(Vector3(x,y,.6),Vector3(.8,.12,.12),tint)
            _prop(Vector3(0,5,-.8),Vector3(15,.7,1.4),tint.darkened(.6))
        2:
            for x in [-7.0,-4.0,4.0,7.0]:_prop(Vector3(x,3,-1.5),Vector3(.7,6,1),tint.darkened(.5))
            _prop(Vector3(0,6.2,-1.5),Vector3(18,.8,3),Color("292b40"))
            for x in range(-8,9,2):_prop(Vector3(x,5.7,-.2),Vector3(.9,.12,.15),tint)
        3:
            for x in [-6.8,6.8]:
                for y in [.65,1.95]:
                    _prop(Vector3(x,y,-.5),Vector3(2.6,1.2,1.7),tint.darkened(.4))
                    for rib in [-.8,-.4,0,.4,.8]:_prop(Vector3(x+rib,y,.37),Vector3(.06,1.1,.05),tint)
        4:
            for x in [-7.0,-5.5,5.5,7.0]:
                _prop(Vector3(x,.4,.7),Vector3(.35,.8,.35),Color("e89441"))
                _prop(Vector3(x,.6,.7),Vector3(.38,.15,.38),Color.WHITE)
            for x in [-6.0,6.0]:_prop(Vector3(x,3,-.7),Vector3(2.3,.7,.3),tint)
        5:
            for x in [-7.0,7.0]:
                _prop(Vector3(x,3,-1),Vector3(1.3,6,1.7),Color("262a42"))
                _prop(Vector3(x,3,.0),Vector3(.18,5.5,.1),tint)
            for y in [5.0,5.7]:_prop(Vector3(0,y,-1),Vector3(15,.15,.3),Color("ff008c"))
