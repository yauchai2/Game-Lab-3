extends CanvasLayer
## Nightshift workshop: spatial interactions over the existing campaign/save systems.
const T=preload("res://scripts/combat/ui/ui_theme.gd")
const Profile=preload("res://scripts/combat/city/city_profile.gd")
const Set=preload("res://scripts/combat/city/nightshift/reference_workshop.gd")
var STATIONS:Array[Vector3]=[]
const NAMES=["SKILLS","CIRCUIT","DEALER","RADIO","DEPART","SHOP"]
const COLORS=Set.ACCENTS
var workshop:Node3D
var route:=PackedVector3Array()
var route_station:=-1
var active_station:=-1
var station_buttons:Array[Button]=[]
var station_bar:HBoxContainer
var hud_expanded:=false
var arrival_hint:Label
var npc_sample:=0.0
var campaign:Node
var root:Control
var layout:Control
var world:Node3D
var viewport:SubViewport
var hero:Node3D
var feet:Array[MeshInstance3D]=[]
var view_camera:Camera3D
var panel:PanelContainer
var stack:VBoxContainer
var header:PanelContainer
var header_row:HBoxContainer
var hint:Label
var page:=""
var selected_slot:=0
var notice:=""
var walk_clock:=0.0
var talent_tree:Control
var inventory_page:=0
var selected_item:=-1
var nearest:=-1
var hero_visual:Node3D
var town_npcs:Array[Node3D]=[]
var speaker:=0
var chapter_review:=-1
var scroll:ScrollContainer
var info:Label
const Pages=preload("res://scripts/combat/city/hub_pages.gd")

func _ready() -> void:
    layer=6
    root=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.theme=T.build();add_child(root)
    var container:=SubViewportContainer.new();container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);container.stretch=true
    container.mouse_filter=Control.MOUSE_FILTER_IGNORE;container.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;root.add_child(container)
    viewport=SubViewport.new();viewport.size=Vector2i(960,540);viewport.own_world_3d=true;container.add_child(viewport)
    world=Node3D.new();viewport.add_child(world);_build_city()
    layout=Control.new();layout.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(layout)
    header=PanelContainer.new();header.add_theme_stylebox_override("panel",T.plate(T.INK,T.EDGE,2));header.position=Vector2(24,22);layout.add_child(header)
    header_row=HBoxContainer.new();header_row.add_theme_constant_override("separation",18);header.add_child(header_row)
    hint=_label("",24,T.PAPER);hint.add_theme_stylebox_override("normal",T.plate(T.INK,T.INK,1));hint.position=Vector2(34,594);hint.size=Vector2(1200,38);layout.add_child(hint)
    var bar:=HBoxContainer.new();station_bar=bar;bar.position=Vector2(30,649);bar.size=Vector2(1220,48);bar.add_theme_constant_override("separation",8);layout.add_child(bar)
    for i in 7:
        var index:=i
        var button:=Button.new();button.text=(str(i+1)+" "+NAMES[i]) if i<6 else "TITLE"
        button.custom_minimum_size=Vector2(166,48);button.add_theme_font_size_override("font_size",24)
        button.pressed.connect(func():
            if index<6:request_station(index)
            else:campaign.leave_city())
        bar.add_child(button)
        if i<6:station_buttons.append(button)
    panel=PanelContainer.new();panel.position=Vector2(632,36);panel.size=Vector2(620,548)
    panel.add_theme_stylebox_override("panel",T.plate(Color("10121f"),T.TEAL,2));layout.add_child(panel)
    var column:=VBoxContainer.new();column.add_theme_constant_override("separation",6);panel.add_child(column)
    scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(scroll)
    info=Label.new();info.add_theme_font_size_override("font_size",20);info.add_theme_color_override("font_color",T.MUTED);info.custom_minimum_size=Vector2(0,52)
    info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;info.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(info)
    stack=VBoxContainer.new();stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stack.add_theme_constant_override("separation",6);scroll.add_child(stack)
    talent_tree=preload("res://scripts/combat/city/city_talent_tree.gd").new();layout.add_child(talent_tree)
    _upgrade_city()
    arrival_hint=_label("",28,T.INK);arrival_hint.add_theme_stylebox_override("normal",T.plate(T.PAPER,T.INK,2));arrival_hint.position=Vector2(30,550);arrival_hint.size=Vector2(640,40);layout.add_child(arrival_hint)
    root.resized.connect(_resize);_resize();hide_city()

func _resize() -> void:
    layout.scale=root.size/Vector2(1280,720)
    layout.size=Vector2(1280,720)

func _box(at:Vector3,extent:Vector3,tint:Color,parent:Node3D=world) -> MeshInstance3D:
    var mesh:=MeshInstance3D.new();var shape:=BoxMesh.new();shape.size=extent;mesh.mesh=shape
    var material:=StandardMaterial3D.new();material.albedo_color=tint;material.roughness=1.0;mesh.material_override=material
    parent.add_child(mesh);mesh.position=at
    return mesh

func _sign(text:String,at:Vector3,tint:Color) -> void:
    var label:=Label3D.new();label.text=text;label.font_size=42;label.pixel_size=.012;label.modulate=tint
    label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.no_depth_test=true;label.outline_size=9
    world.add_child(label);label.position=at

func _build_city() -> void:
    workshop=Set.new();world.add_child(workshop);workshop.build()
    view_camera=workshop.camera;STATIONS=workshop.stations
    hero=Node3D.new();hero.name="ControllableHero";world.add_child(hero)

func show_city() -> void:
    visible=true;root.visible=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    get_viewport().disable_3d=true
    hero.position=workshop.spawns[campaign.hero_id()];route.clear();route_station=-1;page="";panel.visible=false;refresh_header()
    notice=""
    header.visible=hud_expanded;hint.visible=hud_expanded;station_bar.visible=hud_expanded

func hide_city() -> void:
    visible=false
    route.clear();route_station=-1
    if is_instance_valid(talent_tree):talent_tree.hide()
    get_viewport().disable_3d=false
    if is_instance_valid(root):root.visible=false;viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED

func refresh_header() -> void:
    var p=campaign.profile;var d:Dictionary=p.data
    for child in header_row.get_children():header_row.remove_child(child);child.queue_free()
    var W=preload("res://scripts/combat/city/hub_widgets.gd")
    W.chip("coin",str(int(d.credits)),T.LIME,header_row);W.chip("gear",str(int(d.parts)),T.TEAL,header_row)
    W.chip("star","LV%d"%p.level(),T.PAPER,header_row)
    if int(d.points)>0:W.chip("circuit","+%d"%int(d.points),T.CORAL,header_row)
    if not d.run.is_empty():
        W.chip("heart",str(int(d.run.hp)),T.CORAL,header_row)
        if d.run.get("mode","story")=="contract":W.chip("skull","T%d  %d/%d"%[int(d.run.contract.tier),int(d.run.wave)+1,int(d.run.contract.waves)],T.LIME,header_row)
        else:W.chip("flag","%d/18"%(int(d.run.room)+1),T.LIME,header_row)
    header.size=Vector2(0,0)
    workshop.progress(int(d.best))
    if p.error!="":notice=p.error

func _process(delta:float) -> void:
    if not visible:return
    var movement:=Vector2.ZERO
    if not panel.visible and not talent_tree.visible:
        movement=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))).normalized()
        var right:Vector3=view_camera.global_basis.x;right.y=0
        var back:Vector3=view_camera.global_basis.z;back.y=0
        var direction:Vector3=(right.normalized()*movement.x+back.normalized()*movement.y).normalized()
        if movement.length()>.01:route.clear();route_station=-1
        elif not route.is_empty():
            var toward:Vector3=route[0]-hero.position;toward.y=0
            if toward.length()<.07:
                hero.position=route[0];route.remove_at(0)
            else:direction=toward.normalized();movement=Vector2.ONE.normalized()
        hero.position=workshop.move_actor(hero.position,direction*4.0,minf(delta,.05))
        if direction.length()>.1:hero.rotation.y=lerp_angle(hero.rotation.y,atan2(direction.x,direction.z),minf(1,delta*14))
        walk_clock+=delta*12*movement.length()
        if route.is_empty() and route_station>=0:
            var target:=route_station;route_station=-1
            if hero.position.distance_to(STATIONS[target])<1.55:open_station(target)
    _avatar(delta,movement)
    workshop.advance(delta,campaign.session.reduced_effects)
    var previous_nearest:=nearest
    nearest=-1
    var distance:=1.85
    for i in STATIONS.size():
        var gap:float=hero.position.distance_to(STATIONS[i])
        if gap<distance:distance=gap;nearest=i
    workshop.accent_station(nearest)
    if nearest>=0 and nearest!=previous_nearest and not panel.visible:campaign.session.audio.play_sound("ui_move",1.0,-18)
    arrival_hint.visible=nearest>=0 and not panel.visible and not talent_tree.visible
    if arrival_hint.visible:arrival_hint.text=" E / ENTER  "+Set.TITLES[nearest]
    hint.text=notice if notice!="" else ("WALKING TO "+NAMES[route_station]+" / WASD TO CANCEL" if route_station>=0 else "WASD: WALK    E: USE    1-6: GO TO STATION    CLICK: WALK    ESC: CLOSE")

func request_station(index:int) -> void:
    if index<0 or index>=STATIONS.size():return
    if talent_tree.visible:talent_tree.hide()
    close_panel()
    if hero.position.distance_to(STATIONS[index])<1.85:open_station(index);return
    route=workshop.route(hero.position,STATIONS[index]);route_station=index
    if route.is_empty():route_station=-1;notice="Path unavailable / use the stairs to the radio loft."


func _input(event:InputEvent) -> void:
    if not visible or not event is InputEventKey or not event.pressed or event.echo:return
    if event.keycode==KEY_TAB:
        hud_expanded=not hud_expanded;header.visible=hud_expanded;hint.visible=hud_expanded;station_bar.visible=hud_expanded
        get_viewport().set_input_as_handled();return
    if talent_tree.visible:
        if event.keycode==KEY_ESCAPE:talent_tree.hide();refresh_header();get_viewport().set_input_as_handled()
        return
    if event.keycode==KEY_ESCAPE:
        if panel.visible:close_panel()
        else:campaign.leave_city()
    elif event.keycode in [KEY_E,KEY_ENTER] and nearest>=0 and not panel.visible:open_station(nearest)
    elif event.keycode>=KEY_1 and event.keycode<=KEY_6:request_station(event.keycode-KEY_1)
    else:return
    get_viewport().set_input_as_handled()

func close_panel() -> void:
    panel.visible=false;page="";notice=""
    header.visible=hud_expanded
    var focused:=get_viewport().gui_get_focus_owner()
    if focused:focused.release_focus()

func _label(text:String,size:int=24,tint:Color=T.PAPER) -> Label:
    var label:=Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size",size);label.add_theme_color_override("font_color",tint)
    return label

func _text(text:String,tint:Color=T.PAPER) -> void:stack.add_child(_label(text,24,tint))

func _button(text:String,callback:Callable,disabled:=false) -> Button:
    var button:=Button.new();button.text=text;button.custom_minimum_size=Vector2(0,43)
    button.add_theme_font_size_override("font_size",24);button.disabled=disabled
    button.pressed.connect(callback);stack.add_child(button)
    return button

func act(callback:Callable,message:String) -> void:
    var result:Variant=callback.call()
    notice=message if result else "Unavailable / check cost, progress or save status."
    if campaign.profile.error!="":notice=campaign.profile.error
    refresh_header();open_station(NAMES.find(page));set_info(notice)

func open_station(index:int) -> void:
    if index<0 or index>=NAMES.size():return
    route.clear();route_station=-1;active_station=index;workshop.trigger(index)
    campaign.session.audio.play_sound("ui_confirm",1.0,-10)
    page=NAMES[index];panel.visible=true;header.visible=true
    for child in stack.get_children():stack.remove_child(child);child.queue_free()
    info.text=""
    if not index in [0,2,3,4,5]:
        _text(Set.TITLES[index],COLORS[index])
        _button("CLOSE / ESC",close_panel)
    if campaign.profile.migration_notice!="":_text(campaign.profile.migration_notice,T.GOLD)
    if campaign.profile.error!="":
        _text(campaign.profile.error,T.GOLD)
        _button("RELOAD SAVED PROFILE",func():act(campaign.profile.retry_save,"Save reloaded"))
        return
    match index:
        0:Pages.skills(self)
        1:_talents()
        2:Pages.dealer(self)
        3:Pages.story(self)
        4:Pages.depart(self)
        5:Pages.shop(self)
    if talent_tree.visible:return
    for child in stack.find_children("*","Button",true,false):
        if not child.disabled and child.get_meta("act","")!="close":call_deferred("_focus_station_button",weakref(child));break

func _talents() -> void:
    panel.visible=false;talent_tree.open(campaign.profile,campaign.hero_id())

func _scroll_compare() -> void:
    await get_tree().process_frame
    for child in stack.get_children():
        if child.get_meta("compare_start",false):scroll.scroll_vertical=int(child.position.y);return

func _upgrade_city() -> void:
    # Same production roster as combat, never a replacement generated character.
    for i in [1,2,3]:
        var npc:=preload("res://scripts/combat/fighter_visual.gd").new();npc.neon_enabled=true
        world.add_child(npc);npc.setup(Color.WHITE,i);npc.scale=Vector3.ONE*.82
        npc.position=[Vector3(-3.25,0,-3.1),Vector3(-7.0,2.1,-3.8),Vector3(.2,0,-3.6)][i-1]
        npc.rotation.y=.65;town_npcs.append(npc)
func _avatar(delta:float,movement:Vector2) -> void:
    if hero_visual==null:
        hero_visual=preload("res://scripts/combat/fighter_visual.gd").new();hero_visual.neon_enabled=true;hero.add_child(hero_visual);hero_visual.setup(Color("00cad7"),campaign.hero_id());hero_visual.scale=Vector3.ONE*.9
    if hero_visual.character_index!=campaign.hero_id():hero_visual.setup(Color("00cad7"),campaign.hero_id())
    var pose:Dictionary=campaign.session.sim.fighters[0].duplicate(true)
    pose.character=campaign.hero_id();pose.health=100;pose.state="idle";pose.move="";pose.frame=0;pose.x=0.0;pose.y=0.0;pose.vx=movement.length()*4;pose.vy=0.0;pose.face=1;pose.guarding=false;pose.flash=0;pose["air_enabled"]=false
    pose["draw_core"]=campaign.profile.data.pending_core if campaign.profile.data.run.is_empty() else campaign.profile.data.run.get("core","")
    hero_visual.present(pose,delta,false,true);hero_visual.position=Vector3.ZERO;hero_visual.rotation.y=0
    preload("res://scripts/combat/city/campaign_visuals.gd").equipment(hero_visual,campaign.profile.gear_for(campaign.hero_id()))
    var companions:Array=[0,1,2,3];companions.erase(campaign.hero_id())
    for slot in town_npcs.size():
        var npc:Node3D=town_npcs[slot];var id:int=companions[slot]
        if npc.character_index!=id:npc.setup(Color.WHITE,id)
        npc.position=workshop.spawns[id]
    workshop.pose_actor(hero_visual,campaign.hero_id(),movement.length()>.01,campaign.session.reduced_effects)
    npc_sample+=delta
    if npc_sample>=1.0/12:
        for npc in town_npcs:
            npc.visible=true
            var old:Transform3D=npc.transform
            var idle_pose:Dictionary=pose.duplicate(true);idle_pose.character=npc.character_index;idle_pose.vx=0;idle_pose.draw_core=""
            npc.present(idle_pose,npc_sample,false,true);npc.transform=old
            workshop.pose_actor(npc,npc.character_index,false,campaign.session.reduced_effects)
            var job:int=[-1,0,3,1][npc.character_index]
            if workshop.action_station==job and workshop.action_age<.85:
                var weight:float=sin(workshop.action_age/.85*PI)
                npc.motions._aim_limb("RightArm","RightForeArm",npc.motions.model_forward*.9-npc.motions.model_up*.3,weight)
                npc.motions._aim_limb("RightForeArm","RightHand",npc.motions.model_forward*.8+npc.motions.model_up*.25,weight)
                npc.skeleton.force_update_all_bone_transforms()
            if hero.position.distance_to(npc.position)<3.5:npc.rotation.y=lerp_angle(npc.rotation.y,atan2(hero.position.x-npc.position.x,hero.position.z-npc.position.z),.2)
        npc_sample=0.0

func _focus_station_button(button_ref:WeakRef) -> void:
    var button:Button=button_ref.get_ref()
    if is_instance_valid(button) and button.is_inside_tree() and button.is_visible_in_tree():button.grab_focus()

func _unhandled_input(event:InputEvent) -> void:
    if not visible or panel.visible or talent_tree.visible:return
    if not event is InputEventMouseButton or event.button_index!=MOUSE_BUTTON_LEFT or not event.pressed:return
    var point:Vector2=event.position
    var aims:Array=workshop.aims
    var picked:=-1;var gap:=42.0
    for i in aims.size():
        var distance:float=view_camera.unproject_position(aims[i]).distance_to(point)
        if distance<gap:picked=i;gap=distance
    if picked>=0:request_station(picked);get_viewport().set_input_as_handled();return
    var origin:Vector3=view_camera.project_ray_origin(point);var direction:Vector3=view_camera.project_ray_normal(point)
    var target:Variant=Plane(Vector3.UP,0).intersects_ray(origin,direction)
    var upstairs:Variant=Plane(Vector3.UP,Set.LOFT_Y).intersects_ray(origin,direction)
    if upstairs!=null and workshop.in_loft(upstairs):target=upstairs
    if target!=null and workshop.walkable(target):
        route=workshop.route(hero.position,target);route_station=-1
        get_viewport().set_input_as_handled()

func set_info(text:String) -> void:
    if is_instance_valid(info):info.text=text
