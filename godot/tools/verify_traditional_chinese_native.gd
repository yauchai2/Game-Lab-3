extends SceneTree
const OUT="res://../docs/evidence/traditional-chinese/"
var s:Node
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("ZH_NATIVE ",label," ",ok)
    if not ok:push_error(label)
func frames(n:=4) -> void:
    for i in n:await process_frame
    await RenderingServer.frame_post_draw
func tap(code:Key) -> void:
    for down in [true,false]:
        var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down;Input.parse_input_event(event);await frames(2)
func click(control:Control) -> void:
    await frames()
    var ancestor:=control.get_parent()
    while ancestor:
        if ancestor is ScrollContainer:ancestor.ensure_control_visible(control);await frames();break
        ancestor=ancestor.get_parent()
    for down in [true,false]:
        var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=root.get_screen_transform()*control.get_global_rect().get_center();event.global_position=event.position;Input.parse_input_event(event);await frames(2)
func shot(label:String) -> void:
    s.hud.queue_redraw();await frames();root.get_texture().get_image().save_png(OUT+label+".png")
func spawn() -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="user://traditional-chinese/native-options.cfg";s.city_save_path="user://traditional-chinese/native-city.json";s.progression_path="";s.story_opening_on_boot=false;root.add_child(s);s.audio.muted=true;s.set_process(false);s.set_physics_process(false);await frames(6)
func run() -> void:
    root.gui_embed_subwindows=true
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    for file in ["native-options.cfg","native-city.json","native-city.json.bak"]:DirAccess.remove_absolute(ProjectSettings.globalize_path("user://traditional-chinese/"+file))
    await spawn();s.return_to_title();s.hud.open_page("settings");await frames()
    var option:OptionButton
    for node in s.hud.menu_stack.get_children():
        if node is OptionButton and node.get_meta("ui_key","")=="language":option=node;break
    check("Settings have English and Traditional Chinese choices",option!=null and option.item_count==2 and option.get_item_text(1)=="繁體中文")
    var snapshot:Array=s.sim.fighters.duplicate(true)
    await click(option)
    # Activate the native popup item through its public signal, exercising the
    # OptionButton callback and persistence without OS popup key routing.
    var popup:=option.get_popup()
    popup.index_pressed.emit(1)
    if is_instance_valid(popup):popup.hide()
    await frames(5)
    check("Native popup selection switches and saves the locale",s.language=="zh" and TranslationServer.get_locale().begins_with("zh"))
    check("Changing language does not change fighter state",snapshot==s.sim.fighters)
    await shot("settings-zh")
    s.hud.close_page();await shot("title-zh")
    for page in ["help","roster","labs"]:s.hud.open_page(page);await shot(page+"-zh")
    s.hud.close_page();s.city_campaign.open_city();await frames()
    var c=s.city_campaign;var p=c.profile;var h=c.hub
    p.data.best=18;p.data.xp=1900;p.data.credits=1000;p.data.parts=100;p._points();p.pull(0,0);p.save_data()
    var profile_snapshot:Dictionary=p.data.duplicate(true)
    await shot("city-zh")
    for station in 6:
        h.talent_tree.hide();h.open_station(station);await shot("station-%d-zh"%station);h.close_panel();h.talent_tree.hide()
    h.talent_tree.open(p,0);h.talent_tree.selected="break_1";h.talent_tree._detail();await shot("talent-zh");h.talent_tree.hide()
    check("Localized city pages preserve the profile",profile_snapshot==p.data)
    var cards:Array=c.flow.Lines.cards(c.flow.Lines.PROLOGUE,0)
    c.flow.play_cards(cards,func():pass);c.flow._process(1.0);await shot("story-zh")
    var queued:int=c.flow.queue.size();c.flow._advance_card()
    check("Chinese typewriter advances when the translated line is complete",c.flow.queue.size()==queued-1)
    c.flow._hide_all()
    c.leave_city();s.start_match(true);s._process(.1);s.pause_game();await shot("pause-zh")
    check("Native pause button copy is Chinese",s.hud.menu_stack.find_children("*","Button",true,false).any(func(b):return str(b.tr(b.text)).contains("繼續")))
    s.queue_free();await frames(8)
    await spawn();check("Restart restores saved Traditional Chinese",s.language=="zh")
    s.set_language("en");s.return_to_title();await shot("title-en")
    check("English remains selectable after restart",s.language=="en" and TranslationServer.get_locale()=="en")
    s.queue_free();await frames(8)
    var failed:int=checks.filter(func(c):return not c.passed).size()
    FileAccess.open(OUT+"native.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"scope":"Native click/captures with semantic PopupMenu activation; late city pages use explicit best/funding fixtures, not earned progress."},"  "))
    quit(0 if failed==0 else 1)
