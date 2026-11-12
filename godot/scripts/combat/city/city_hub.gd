extends CanvasLayer
## Procedural 45-degree orthographic safe hub; no generated/imported art required.
const T=preload("res://scripts/combat/ui/ui_theme.gd")
const Profile=preload("res://scripts/combat/city/city_profile.gd")
const STATIONS=[Vector3(-5,0,0),Vector3(-3,0,-4),Vector3(2,0,-4),Vector3(5,0,0),Vector3(1,0,4)]
const NAMES=["SKILLS","CIRCUIT","DEALER","RADIO","DEPART"]
const COLORS=[Color("00cad7"),Color("c5ef33"),Color("ff008c"),Color("ffc255"),Color("ffffff")]
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
var header:Label
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

func _ready() -> void:
    layer=6
    root=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.theme=T.build();add_child(root)
    var container:=SubViewportContainer.new();container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);container.stretch=true
    container.mouse_filter=Control.MOUSE_FILTER_IGNORE;container.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;root.add_child(container)
    viewport=SubViewport.new();viewport.size=Vector2i(1280,720);viewport.own_world_3d=true;container.add_child(viewport)
    world=Node3D.new();viewport.add_child(world);_build_city()
    layout=Control.new();layout.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(layout)
    header=_label("",30,T.PAPER);header.position=Vector2(34,22);header.size=Vector2(1220,74);layout.add_child(header)
    hint=_label("",24,T.GOLD);hint.position=Vector2(34,594);hint.size=Vector2(1200,38);layout.add_child(hint)
    var bar:=HBoxContainer.new();bar.position=Vector2(30,649);bar.size=Vector2(1220,48);bar.add_theme_constant_override("separation",8);layout.add_child(bar)
    for i in 6:
        var index:=i
        var button:=Button.new();button.text=(str(i+1)+" "+NAMES[i]) if i<5 else "TITLE"
        button.custom_minimum_size=Vector2(195,48);button.add_theme_font_size_override("font_size",24)
        button.pressed.connect(func():
            if index<5:open_station(index)
            else:campaign.leave_city())
        bar.add_child(button)
    panel=PanelContainer.new();panel.position=Vector2(712,112);panel.size=Vector2(536,464)
    panel.add_theme_stylebox_override("panel",T.plate(Color("10121f"),T.TEAL,2));layout.add_child(panel)
    var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;panel.add_child(scroll)
    stack=VBoxContainer.new();stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stack.add_theme_constant_override("separation",10);scroll.add_child(stack)
    talent_tree=preload("res://scripts/combat/city/city_talent_tree.gd").new();layout.add_child(talent_tree)
    _upgrade_city()
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
    var environment:=WorldEnvironment.new();var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR;env.background_color=Color("15142b")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("9296bf");env.ambient_light_energy=.7
    environment.environment=env;world.add_child(environment)
    var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-55,-35,0);light.light_energy=1.5;world.add_child(light)
    _box(Vector3(0,-.35,0),Vector3(18,.6,17),Color("27283a"))
    for x in range(-8,9,2):
        for z in range(-8,9,2):_box(Vector3(x,-.025,z),Vector3(1.94,.04,1.94),Color("343447") if (x+z)%4==0 else Color("39394e"))
    # Rear facades leave the playable square and front approach unobstructed.
    for i in 6:
        var height:=2.5+float(i%3)
        var at:=Vector3(-7.5+i*3.0,height*.5,-8)
        _box(at,Vector3(2.8,height,1.4),Color("252336"))
        for row in int(height):
            _box(at+Vector3(0,row-height*.5+.7,.73),Vector3(1.9,.25,.05),Color("605b83"))
    for z in [-6,-2,2,6]:_box(Vector3(-8,1.4,z),Vector3(.25,2.8,.25),Color("5c5978"))
    _box(Vector3(-8,2.9,0),Vector3(.25,.18,14),Color("00a9b6"))
    _box(Vector3(0,0.01,0),Vector3(1.4,.05,12),Color("51516b"))
    _box(Vector3(0,.015,0),Vector3(12,.05,1.4),Color("51516b"))
    for i in 5:
        var at:Vector3=STATIONS[i];var tint:Color=COLORS[i]
        _box(at+Vector3(0,.12,0),Vector3(2.2,.24,2.2),tint.darkened(.5))
        if i==4:
            _box(at+Vector3(-.9,1.4,0),Vector3(.25,2.6,.3),tint)
            _box(at+Vector3(.9,1.4,0),Vector3(.25,2.6,.3),tint)
            _box(at+Vector3(0,2.7,0),Vector3(2,.25,.3),Color("ff008c"))
        elif i==2:
            _box(at+Vector3(0,.8,0),Vector3(1.3,1.4,1.0),Color("46233c"))
            for x in [-.35,0,.35]:_box(at+Vector3(x,1.1,.52),Vector3(.24,.45,.08),tint)
            _box(at+Vector3(0,1.8,0),Vector3(1.8,.2,1.4),tint)
        elif i==3:
            _box(at+Vector3(0,.7,0),Vector3(.7,1.2,.5),Color("755c43"))
            _box(at+Vector3(0,1.5,0),Vector3(.5,.5,.5),Color("ffc255"))
            _box(at+Vector3(.7,.8,0),Vector3(.7,1.0,.7),Color("444050"))
        else:
            _box(at+Vector3(0,.65,0),Vector3(1.2,1.1,.8),Color("32384a"))
            var screen:=_box(at+Vector3(0,1.3,0),Vector3(1.2,.65,.12),tint);screen.rotation_degrees.x=-25
        _sign(NAMES[i],at+Vector3(0,3.2,0),tint)
    # Planters, crates, benches and traffic bollards are replaceable placeholders.
    for at in [Vector3(-6,0,5.5),Vector3(6,0,5.5),Vector3(-6,0,-5.7)]:
        _box(at+Vector3(0,.3,0),Vector3(1.5,.6,1.5),Color("675c67"))
        _box(at+Vector3(0,1.0,0),Vector3(1.2,.9,1.2),Color("65764f"))
    for i in 4:_box(Vector3(4+i*.6,.3,6.7),Vector3(.25,.6,.25),Color("dba153"))
    _sign("AFTERHOURS / SAFE BLOCK",Vector3(0,4.5,-7),Color("ff008c"))
    hero=Node3D.new();world.add_child(hero)
    _box(Vector3(0,.85,0),Vector3(.55,.9,.4),Color("00cbd9"),hero)
    _box(Vector3(0,1.5,0),Vector3(.5,.5,.45),Color("161523"),hero)
    _box(Vector3(0,1.5,-.24),Vector3(.32,.15,.05),Color("bafaff"),hero)
    for x in [-.17,.17]:feet.append(_box(Vector3(x,.22,0),Vector3(.23,.45,.28),Color("e6defa"),hero))
    view_camera=Camera3D.new();view_camera.projection=Camera3D.PROJECTION_ORTHOGONAL;view_camera.size=22
    world.add_child(view_camera);view_camera.position=Vector3(17,17*sqrt(2.0),17);view_camera.look_at(Vector3.ZERO);view_camera.current=true

func show_city() -> void:
    visible=true;root.visible=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    get_viewport().disable_3d=true
    hero.position=Vector3(0,0,1.5);page="";panel.visible=false;refresh_header()

func hide_city() -> void:
    visible=false
    if is_instance_valid(talent_tree):talent_tree.hide()
    get_viewport().disable_3d=false
    if is_instance_valid(root):root.visible=false;viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED

func refresh_header() -> void:
    var p=campaign.profile;var d:Dictionary=p.data
    var progress:="NEW EXPEDITION" if d.run.is_empty() else "ROOM %d / 18   HP %d"%[int(d.run.room)+1,int(d.run.hp)]
    header.text="SAFE BLOCK / %s\n%d CREDITS   %d PARTS   LV%d   %d POINTS"%[progress,int(d.credits),int(d.parts),p.level(),int(d.points)]
    if not d.run.is_empty() and d.run.get("mode","story")=="contract":
        header.text="SAFE BLOCK / T%d / WAVE %d OF %d / %d ATTEMPTS\n%d CREDITS / LV%d / HP %d"%[int(d.run.contract.tier),int(d.run.wave)+1,int(d.run.contract.waves),int(d.run.tries),int(d.credits),p.level(),int(d.run.hp)]
    if p.error!="":notice=p.error

func _process(delta:float) -> void:
    if not visible:return
    var movement:=Vector2.ZERO
    if not panel.visible and not talent_tree.visible:
        movement=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))).normalized()
        # Screen-relative input under a 45-degree camera.
        var direction:=Vector3(movement.x+movement.y,0,movement.y-movement.x).normalized()
        var step:=direction*4.0*delta
        for axis in [0,2]:
            var candidate:Vector3=hero.position;candidate[axis]+=step[axis]
            var blocked:=false
            for i in 4:
                if candidate.distance_to(STATIONS[i])<1.0:blocked=true;break
            for obstacle in [Vector3(-6,0,5.5),Vector3(6,0,5.5),Vector3(-6,0,-5.7)]:
                if candidate.distance_to(obstacle)<1.1:blocked=true;break
            if not blocked:hero.position=candidate
        hero.position.x=clampf(hero.position.x,-6.6,6.6);hero.position.z=clampf(hero.position.z,-6,6)
        if direction.length()>.1:hero.rotation.y=atan2(-direction.x,-direction.z)
        walk_clock+=delta*12*movement.length()
    _avatar(delta,movement)
    for i in feet.size():feet[i].position.y=.22+sin(walk_clock+i*PI)*.09*movement.length()
    nearest=-1
    for i in 5:
        if hero.position.distance_to(STATIONS[i])<2.15:nearest=i;break
    hint.text=notice if notice!="" else ("E  "+NAMES[nearest] if nearest>=0 and not panel.visible else "WASD / ARROWS  WALK     E  INTERACT     1-5  STATIONS     ESC  CLOSE")

func _input(event:InputEvent) -> void:
    if not visible or not event is InputEventKey or not event.pressed or event.echo:return
    if talent_tree.visible:
        if event.keycode==KEY_ESCAPE:talent_tree.hide();refresh_header();get_viewport().set_input_as_handled()
        return
    if event.keycode==KEY_ESCAPE:
        if panel.visible:close_panel()
        else:campaign.leave_city()
    elif event.keycode==KEY_E and nearest>=0 and not panel.visible:open_station(nearest)
    elif event.keycode>=KEY_1 and event.keycode<=KEY_5:open_station(event.keycode-KEY_1)
    else:return
    get_viewport().set_input_as_handled()

func close_panel() -> void:
    panel.visible=false;page="";notice=""
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
    refresh_header();open_station(NAMES.find(page))

func open_station(index:int) -> void:
    if index<0 or index>4:return
    page=NAMES[index];panel.visible=true
    for child in stack.get_children():stack.remove_child(child);child.queue_free()
    _text(page,T.TEAL)
    _button("CLOSE / ESC",close_panel)
    if campaign.profile.migration_notice!="":_text(campaign.profile.migration_notice,T.GOLD)
    if campaign.profile.error!="":
        _text(campaign.profile.error,T.GOLD)
        _button("RELOAD SAVED PROFILE",func():act(campaign.profile.retry_save,"Save reloaded"))
        return
    match index:
        0:_skills()
        1:_talents()
        2:_shop()
        3:_story()
        4:_map()
    if talent_tree.visible:return
    for child in stack.get_children():
        if child is Button and not child.disabled:child.call_deferred("grab_focus");break

func _skills() -> void:
    var p=campaign.profile
    var hero_id:int=campaign.hero_id()
    var rank:=int(p.data.skill_levels[hero_id])
    _text("CLASS SKILL RANK %d / 3. Each rank: +5%% basic L damage."%rank,T.GOLD)
    _button("UPGRADE L / 30 CREDITS + %d PARTS"%(2+rank),func():act(func():return p.upgrade_skill(hero_id),"Class skill upgraded"),rank>=3 or p.data.credits<30 or p.data.parts<2+rank)
    _text("Permanent skills / story milestones. No random unlocks.")
    _text("PRACTICE lessons use safe fixtures and award no loot.",T.GOLD)
    for skill in Profile.SKILLS:
        var id:String=skill.id
        var owned:bool=id in p.data.skills
        _button(("LEARNED  " if owned else "LEARN  ")+skill.name+" / CLEAR %d"%skill.at,func():act(func():return p.learn(id),"Skill learned"),owned or int(p.data.best)<skill.at)
        if owned:_button("PRACTICE "+skill.name,func():campaign.start_lesson(id))
    _text("CLASS TECHNIQUES / EQUIP TWO",T.TEAL)
    for i in 3:
        var skill:Dictionary=p.Advanced.SKILLS[hero_id][i];var id:String=skill.id
        var owned:bool=id in p.data.advanced[hero_id]
        _text(skill.desc)
        _button(("UNEQUIP " if owned else "EQUIP ")+skill.name+" / CLEAR %d"%[9,12,15][i],func():act(func():return p.advanced_skill(hero_id,id),"Class technique updated"),int(p.data.best)<[9,12,15][i] or (not owned and p.data.advanced[hero_id].size()>=2))
    _text("Movement, dodge, guard, throws and your basic class skill are available from the start.")

func _talents() -> void:
    panel.visible=false;talent_tree.open(campaign.profile,campaign.hero_id())

func _shop() -> void:
    var p=campaign.profile;var hero_id:int=campaign.hero_id()
    _text("GEAR CAPS: +12% direct damage / +10% defence. Total damage +50%, mitigation 20%, saving 20%. Read openings; gear does not add invulnerability.",T.GOLD)
    _text("CORE READY: "+str(p.data.pending_core).to_upper())
    _text("Nine equally likely cores. One slot per expedition; healing budget survives retries. Prepare here between encounters.")
    _button("DEALER / CORE DRAW + EQUIP / 1 PART",campaign.start_core_draw,not p.can_prepare_core() or (p.data.parts<1 and p.data.core_offer.is_empty()))
    _text("%s / 100 CREDITS"%Profile.SLOTS[selected_slot],T.GOLD)
    _button("CHANGE SLOT > "+Profile.SLOTS[(selected_slot+1)%3],func():selected_slot=(selected_slot+1)%3;open_station(2))
    _button("DRAW SELECTED SLOT / 100 CREDITS",func():
        var item:Dictionary=p.pull(selected_slot,hero_id)
        notice="Received "+str(item.get("name","nothing"));refresh_header();open_station(2),p.data.credits<100 or p.data.inventory.size()+p.data.stash.size()>=180)
    _text("WHITE25 / BLUE55 / RARE19 / SIGNATURE1%%
PITY %d/10 RARE / %d/40 SIGNATURE"%[int(p.data.pity),int(p.data.unique_pity)])
    _button("HEAL 40 HP / 25 CREDITS",func():act(p.heal,"Recovered up to 40 HP"),p.data.run.is_empty() or p.data.credits<25 or int(p.data.run.get("hp",100))>=100)
    var all_items:Array=p.data.inventory+p.data.stash
    for item in all_items:
        if int(item.id)!=selected_item:continue
        _text("COMPARE / SELECTED",T.TEAL);stack.get_child(stack.get_child_count()-1).set_meta("compare_start",true);_text(p.Loot.describe(item))
        var current:Dictionary=p.gear_for(hero_id)[int(item.slot)]
        _text("CURRENT: "+p.Loot.describe(current),T.GOLD)
        var before:Dictionary=p.stats(hero_id)
        p.data.loadouts[hero_id][int(item.slot)]=item
        var after:Dictionary=p.stats(hero_id);p.data.loadouts[hero_id][int(item.slot)]=current
        _text("BUILD CHANGE: DAMAGE %+d%% / DEFENCE %+d%% / SAVING %+d%%"%[roundi((after.damage-before.damage)*100),roundi((after.defence-before.defence)*100),roundi((after.economy-before.economy)*100)])
        var id:=int(item.id)
        _button("EQUIP FOR THIS HERO",func():act(func():return p.equip(id,hero_id),"Equipment fitted"),not current.is_empty() and int(current.id)==id)
        _button("RECALIBRATE FIRST AFFIX / 80 + 5 PARTS",func():act(func():return p.craft(id,"recalibrate",0),"Affix recalibrated"),item.get("affixes",[]).is_empty() or p.data.credits<80 or p.data.parts<5)
        _button("TEMPER / REROLL / 120 + 6 / MAX RARE",func():act(func():return p.craft(id,"temper"),"Equipment tempered"),int(item.tier)>=2 or p.data.credits<120 or p.data.parts<6)
        _button("RECYCLE / +%d PARTS"%(1+int(item.tier)),func():act(func():return p.salvage(id),"Equipment recycled"),p.is_equipped(id))
        break
    _text("EQUIPPED / "+["ZIP","RIVET","HUSH","LOOP"][hero_id],T.TEAL)
    for i in 3:
        var slot:=i;var gear:Dictionary=p.gear_for(hero_id)[i]
        _text(p.Loot.describe(gear))
        if not gear.is_empty():_button("UNEQUIP "+Profile.SLOTS[i],func():act(func():return p.unequip(slot,hero_id),"Slot cleared"))
    _text("BAG %d/60 / STASH %d/120"%[p.data.inventory.size(),p.data.stash.size()],T.GOLD)
    inventory_page=clampi(inventory_page,0,maxi(0,floori(float(all_items.size()-1)/8.0)))
    for i in range(inventory_page*8,mini(all_items.size(),inventory_page*8+8)):
        var item:Dictionary=all_items[i];var id:=int(item.id)
        _button("INSPECT #%d %s"%[id,item.name],func():selected_item=id;open_station(2);call_deferred("_scroll_compare"))
    _button("PREVIOUS ITEMS",func():inventory_page-=1;open_station(2),inventory_page==0)
    _button("NEXT ITEMS",func():inventory_page+=1;open_station(2),(inventory_page+1)*8>=all_items.size())

func _story() -> void:
    var p=campaign.profile
    var current:int=p.Story.chapter(int(p.data.best))
    var chapter:int=current if chapter_review<0 else mini(current,chapter_review)
    var entry:Dictionary=p.Story.CHAPTERS[chapter]
    _text(entry.title,T.GOLD)
    for i in 3:
        var index:=i
        _button(["KEEPER","DEALER","MECHANIC"][i],func():speaker=index;open_station(3))
    _text(p.Story.dialogue(int(p.data.best),speaker) if chapter_review<0 else str(entry.intro))
    _text("MISSION: "+str(entry.objective),T.TEAL)
    if int(p.data.best)>=(chapter+1)*3:_text(entry.outro)
    _text("TECHNIQUE JOURNAL / FIRST SUCCESS REWARDS",T.GOLD)
    for id in p.Story.TECHNIQUES:_text(("DONE / " if id in p.data.quest_claims else "TRY / ")+str(p.Story.TECHNIQUES[id]))
    for i in mini(6,current+1):
        var index:=i
        _button("REVIEW "+str(p.Story.CHAPTERS[i].title),func():chapter_review=index;open_station(3))
    _button("CURRENT CHAPTER",func():chapter_review=-1;open_station(3))
    _button("PRACTICE GANTRY WARDEN",func():campaign.start_lesson("boss","gantry"),p.data.best<9)
    _button("PRACTICE SIGNAL LEVIATHAN",func():campaign.start_lesson("boss","signal"),p.data.best<15)
    for reward in p.data.last_loot:_text(str(reward),T.GOLD)

func _map() -> void:
    var p=campaign.profile
    var chapter:int=p.Story.chapter(int(p.data.best))
    _text(p.Story.CHAPTERS[chapter].title,T.GOLD)
    _button("MISSION BRIEF / STORY",func():open_station(3))
    if not p.data.run.is_empty():
        if p.data.run.boon_due:
            _text("SALVAGED CURRENT / CHOOSE ONE\nActual gain shown after caps. Lost on defeat.",T.GOLD)
            for stat in ["damage","defence","economy"]:
                var id:String=stat
                _button("TAKE "+stat.to_upper()+" (+%d%%)"%roundi(p.boon_gain(id)*100),func():act(func():return p.choose_boon(id),"Current absorbed"),p.boon_gain(id)<=0)
        if p.data.run.boon_due:_button("TAKE 10 CREDITS INSTEAD",func():act(p.skip_boon,"Current exchanged"))
        if p.data.run.get("route_due",false):
            _text("CHOOSE NEXT ROUTE / CONTINUE DEFAULTS TO COMBAT",T.TEAL)
            for route in p.route_options():
                var id:String=route
                _button({"combat":"COMBAT / NORMAL LOOT","cache":"SALVAGE / EXTRA HEAVY + EXTRA ITEM","hazard":"CHARGED STREET / DANGER +20% CREDITS","rest":"REST STOP / +20 HP ONCE"}[route],func():act(func():return p.choose_route(id),"Route committed"))
        _text("EXPEDITION CORE: "+str(p.data.run.get("core","NONE")).to_upper())
        var room:=int(p.data.run.room)
        if p.data.run.get("mode","story")=="contract":
            _text(p.Contracts.describe(p.data.run.contract),T.GOLD)
            _text("WAVE %d / %d / ATTEMPTS %d"%[int(p.data.run.wave)+1,int(p.data.run.contract.waves),int(p.data.run.tries)])
        else:_text("CONTINUE: %s / %d OF 3\nHP %d / METER %d"%[Profile.DISTRICTS[mini(5,floori(float(room)/3.0))],room%3+1,int(p.data.run.hp),int(p.data.run.meter)])
        _button("DEPART / CONTINUE",campaign.depart,bool(p.data.run.boon_due))
        _button("END EXPEDITION / KEEP BANKED LOOT",func():act(p.abandon,"Expedition ended; temporary current cleared"))
    else:
        _text("Choose a cleared district or push the next route. Each district has three encounters.")
    # A schematic city map is usable even while detailed geography is placeholder.
    var board:=Control.new();board.set_meta("city_board","map");board.custom_minimum_size=Vector2(474,198);stack.add_child(board)
    board.draw.connect(func():
        for i in 5:
            board.draw_line(Vector2(34+(i%3)*165,25+floori(float(i)/3.0)*90),Vector2(34+((i+1)%3)*165,25+floori(float(i+1)/3.0)*90),T.TEAL,3))
    for i in 6:
        var sector:=i;var unlocked:bool=i<=mini(5,floori(float(p.data.best)/3.0))
        var button:=Button.new();button.position=Vector2((i%3)*165,floori(float(i)/3.0)*90);button.size=Vector2(145,66)
        button.text=str(i+1)+"\n"+Profile.DISTRICTS[i];button.add_theme_font_size_override("font_size",18)
        button.disabled=not unlocked or not p.data.run.is_empty()
        button.pressed.connect(func():
            if p.start_run(campaign.hero_id(),sector):campaign.depart())
        board.add_child(button)
    if p.data.run.is_empty():
        _text("HERO: "+["ZIP","RIVET","HUSH","LOOP"][campaign.hero_id()])
        _button("CHANGE HERO",func():campaign.selected_hero=(campaign.selected_hero+1)%4;open_station(4))
    if p.data.best>=18:
        _text("STREET CONTRACTS / T%d UNLOCKED"%int(p.data.contract_tier),T.TEAL)
        _text("Clear returns a same-tier contract. Two clears of a tier guarantee the next tier. Free district clears supply T1.")
        for contract in p.data.contracts:
            var id:=int(contract.id)
            _text(Profile.DISTRICTS[int(contract.sector)]+" / "+p.Contracts.describe(contract))
            if int(contract.tier)==5:_text("FINAL BOSS: "+("GANTRY WARDEN" if int(contract.sector)<4 else "SIGNAL LEVIATHAN"),T.GOLD)
            _button("START CONTRACT #%d"%id,func():
                if p.start_contract(campaign.hero_id(),id):campaign.depart(),not p.data.run.is_empty())
    _text("Defeat ends the expedition; credits, gear, skills and talents stay. Cleared encounters bank rewards once. Safe returns preserve HP and current.")

func _scroll_compare() -> void:
    await get_tree().process_frame
    for child in stack.get_children():
        if child.get_meta("compare_start",false):panel.get_child(0).scroll_vertical=int(child.position.y);return

func _upgrade_city() -> void:
    for child in world.get_children():
        if child is MeshInstance3D:world.remove_child(child);child.queue_free()
    var scene:Node3D=load("res://assets/campaign/generated/safe_block.glb").instantiate();world.add_child(scene)
    preload("res://scripts/combat/city/campaign_stage_view.gd").paint(scene)
    feet.clear()
    for child in hero.get_children():hero.remove_child(child);child.queue_free()
    for i in 3:
        var npc:Node3D=load("res://assets/campaign/generated/%s.glb"%["city_keeper","city_dealer","city_mechanic"][i]).instantiate()
        world.add_child(npc);npc.position=[Vector3(5,0,.8),Vector3(2,0,-3),Vector3(-3,0,-3.1)][i];town_npcs.append(npc)
        preload("res://scripts/combat/city/campaign_stage_view.gd").paint(npc)
func _avatar(delta:float,movement:Vector2) -> void:
    if hero_visual==null:
        hero_visual=preload("res://scripts/combat/fighter_visual.gd").new();hero_visual.neon_enabled=true;hero.add_child(hero_visual);hero_visual.setup(Color("00cad7"),campaign.hero_id());hero_visual.scale=Vector3.ONE*.9
    if hero_visual.character_index!=campaign.hero_id():hero_visual.setup(Color("00cad7"),campaign.hero_id())
    var pose:Dictionary=campaign.session.sim.fighters[0].duplicate(true)
    pose.character=campaign.hero_id();pose.health=100;pose.state="idle";pose.move="";pose.frame=0;pose.x=0.0;pose.y=0.0;pose.vx=movement.length()*4;pose.vy=0.0;pose.face=1;pose.guarding=false;pose.flash=0;pose["air_enabled"]=false
    pose["draw_core"]=campaign.profile.data.pending_core if campaign.profile.data.run.is_empty() else campaign.profile.data.run.get("core","")
    hero_visual.present(pose,delta,false,true);hero_visual.position=Vector3.ZERO;hero_visual.rotation.y=PI
    preload("res://scripts/combat/city/campaign_visuals.gd").equipment(hero_visual,campaign.profile.gear_for(campaign.hero_id()))
    for npc in town_npcs:npc.rotation.y=atan2(hero.position.x-npc.position.x,hero.position.z-npc.position.z)
