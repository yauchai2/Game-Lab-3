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
    if last_result!="":hub.notice=last_result
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
    sim.wave_recipes=[profile.recipe(room)]
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
        var hp:=int(session.sim.fighters[0].health);var meter:=float(session.sim.fighters[0].meter)
        if not profile.settle(won,hp,meter):
            session.hud.notice=profile.error;session.hud.notice_time=6;return
        settlement_done=true
        last_result="Encounter banked. Choose current at DEPART; new skills may be ready." if won else "Back home. Temporary current lost; permanent progress retained."
        if won and int(profile.data.best)==18:last_result="Tower captain defeated. The signal is back. All six districts can be replayed."
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
    var sign:=Label3D.new();sign.text=profile.DISTRICTS[sector];sign.position=Vector3(0,4.4,-.5)
    sign.font_size=60;sign.pixel_size=.012;sign.modulate=tint;sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED;dressing.add_child(sign)
