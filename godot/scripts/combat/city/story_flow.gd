extends CanvasLayer
const L10n=preload("res://scripts/combat/ui/locale_text.gd")
## Single owner of the between-encounter flow: story cards, the "keep going" intermission and encounter captions.
## It never touches combat state or the save except through CityProfile's own transactions.
## It only runs in a real session (`live()`); scene-instantiating tests keep the old return-to-city behaviour
## unless they set `force_live`.
const T=preload("res://scripts/combat/ui/ui_theme.gd")
const Lines=preload("res://scripts/combat/city/story_script.gd")
var campaign:Node
var force_live:=false
var cfg_path:="user://neon_lab/story_flow.cfg"
var root:Control
var layout:Control
var backdrop:ColorRect
var card_panel:PanelContainer
var header_label:Label
var speaker_label:Label
var text_label:Label
var hint_label:Label
var inter_panel:PanelContainer
var inter_stack:VBoxContainer
var caption:Label
var caption_left:=0.0
var queue:Array=[]
var queue_total:=0
var after:Callable=Callable()
var typed:=0.0
var mode:=""
var streak:=0
var auto_clock:=0.0
var inter_info:Dictionary={}
var seen:Dictionary={}

func _ready() -> void:
    layer=7
    root=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.theme=T.build();root.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(root)
    layout=Control.new();layout.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(layout)
    backdrop=ColorRect.new();backdrop.color=Color(0,0,0,.78);backdrop.size=Vector2(1280,720);layout.add_child(backdrop)
    card_panel=PanelContainer.new();card_panel.position=Vector2(110,420);card_panel.size=Vector2(1060,220);layout.add_child(card_panel)
    var box:=VBoxContainer.new();box.add_theme_constant_override("separation",8);card_panel.add_child(box)
    header_label=_label("",24,T.TEAL);header_label.position=Vector2(110,330);header_label.size=Vector2(1060,40);layout.add_child(header_label)
    speaker_label=_label("",32,T.PAPER);box.add_child(speaker_label)
    text_label=_label("",28,T.PAPER);text_label.custom_minimum_size=Vector2(1020,130);box.add_child(text_label)
    hint_label=_label("",24,T.MUTED);hint_label.position=Vector2(110,650);hint_label.size=Vector2(1060,34);hint_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;layout.add_child(hint_label)
    inter_panel=PanelContainer.new();inter_panel.position=Vector2(240,70);inter_panel.size=Vector2(800,580)
    inter_panel.add_theme_stylebox_override("panel",T.plate(Color("10121f"),T.TEAL,2));layout.add_child(inter_panel)
    inter_stack=VBoxContainer.new();inter_stack.add_theme_constant_override("separation",9);inter_panel.add_child(inter_stack)
    caption=_label("",26,T.PAPER);caption.add_theme_stylebox_override("normal",T.plate(Color(0,0,0,.82),T.TEAL,2))
    caption.position=Vector2(150,566);caption.size=Vector2(980,68);caption.visible=false;layout.add_child(caption)
    root.resized.connect(_resize);_resize();_hide_all();_load_seen()

func _resize() -> void:
    layout.scale=root.size/Vector2(1280,720);layout.size=Vector2(1280,720)

func _label(text:String,size:int,tint:Color) -> Label:
    var label:=Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size",size);label.add_theme_color_override("font_color",tint)
    return label

func live() -> bool:
    if force_live:return true
    var session:Node=campaign.session if campaign!=null else null
    return session!=null and session.is_inside_tree() and session.get_tree().current_scene==session

func busy() -> bool:return mode!=""

func _hide_all() -> void:
    mode="";queue.clear();backdrop.visible=false;card_panel.visible=false;header_label.visible=false;hint_label.visible=false;inter_panel.visible=false

# ---------------------------------------------------------------- persistence of "seen" scenes
func _load_seen() -> void:
    seen={}
    var cfg:=ConfigFile.new()
    if cfg.load(cfg_path)!=OK:return
    for key in cfg.get_section_keys("seen"):seen[key]=true
    for key in cfg.get_section_keys("ending"):seen["ending_"+key]=true

func _save_seen() -> void:
    var cfg:=ConfigFile.new()
    for key in seen:
        if key.begins_with("ending_"):cfg.set_value("ending",key.trim_prefix("ending_"),true)
        else:cfg.set_value("seen",key,true)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(cfg_path.get_base_dir()))
    cfg.save(cfg_path)

func endings_found() -> int:
    var count:=0
    for id in Lines.ENDINGS:
        if seen.has("ending_"+id):count+=1
    return count

# ---------------------------------------------------------------- cards
func play_cards(cards:Array,then:Callable) -> void:
    if cards.is_empty():then.call();return
    queue=cards.duplicate();queue_total=queue.size();after=then;mode="cards";header_label.text=""
    backdrop.color=Color(0,0,0,1);backdrop.visible=true;card_panel.visible=true;header_label.visible=true;hint_label.visible=true;inter_panel.visible=false;caption.visible=false
    _next_card(false)

func _next_card(advance:=true) -> void:
    if advance and not queue.is_empty():queue.pop_front()
    if queue.is_empty():
        var then:Callable=after;after=Callable();_hide_all();then.call();return
    var card:Dictionary=queue[0];var color:=Color(str(card.color))
    speaker_label.text=card.speaker;speaker_label.add_theme_color_override("font_color",color)
    text_label.text=card.text;text_label.visible_characters=0;typed=0.0
    if card.header!="":header_label.text=card.header
    card_panel.add_theme_stylebox_override("panel",T.plate(Color("0a0c14"),color,3))
    hint_label.text="%d / %d    ENTER: NEXT    ESC: SKIP"%[queue_total-queue.size()+1,queue_total]

func _advance_card() -> void:
    if text_label.visible_characters>=0 and text_label.visible_characters<L10n.text(text_label.text).length():
        text_label.visible_characters=-1;typed=INF;return
    _next_card(true)

func skip_cards() -> void:
    queue.clear();_next_card(false)

# ---------------------------------------------------------------- scenes for the run
func intro_cards() -> Array:
    var p=campaign.profile;var run:Dictionary=p.data.run
    if run.is_empty() or run.get("mode","story")!="story":return []
    var room:int=int(run.room);var hero:int=int(run.hero);var chapter:=Lines.chapter_of(room)
    var result:Array=[]
    if room==0 and not seen.has("prologue"):
        seen["prologue"]=true;result.append_array(Lines.cards(Lines.PROLOGUE,hero))
    if room%3==0 and not seen.has("ch%d"%chapter):
        seen["ch%d"%chapter]=true;result.append_array(Lines.cards(Lines.CHAPTERS[chapter].intro,hero,Lines.CHAPTERS[chapter].title))
    if Lines.BOSS_ENTRANCES.has(room) and not seen.has("boss%d"%room):
        seen["boss%d"%room]=true;result.append_array(Lines.cards(Lines.BOSS_ENTRANCES[room],hero))
    if not result.is_empty():_save_seen()
    return result

func outro_cards(finished_room:int,hero:int) -> Array:
    if finished_room%3!=2 or finished_room>=17:return []
    var chapter:=Lines.chapter_of(finished_room)
    if seen.has("out%d"%chapter):return []
    seen["out%d"%chapter]=true;_save_seen()
    return Lines.cards(Lines.CHAPTERS[chapter].outro,hero,"CHAPTER %d CLEAR"%(chapter+1))

func announce(room:int) -> void:
    var hero:int=int(campaign.hero_id())
    var line:Dictionary=Lines.render(Lines.encounter(room),hero)
    caption.text="%s: %s"%[line.speaker,line.text]
    caption.add_theme_color_override("font_color",Color(str(line.color)))
    caption.visible=true;caption_left=6.5

func finish_ending(ending:String,hero:int,true_ending:bool,then:Callable) -> void:
    seen["ending_"+ending]=true;_save_seen()
    var cards:=Lines.ending_cards(ending,hero,true_ending)
    cards[cards.size()-1].header="ENDINGS FOUND  %d / %d"%[endings_found(),Lines.ENDINGS.size()]
    play_cards(cards,then)

# ---------------------------------------------------------------- intermission
func open_intermission(info:Dictionary) -> void:
    inter_info=info;mode="inter";queue.clear();auto_clock=0.0
    backdrop.color=Color(0,0,0,.8);backdrop.visible=true;card_panel.visible=false;header_label.visible=false;hint_label.visible=true;inter_panel.visible=true;caption.visible=false
    var session:Node=campaign.session
    session.screen="city";session.hud.visible=false;session.pending.clear()
    _build_inter()

func _inter_text(text:String,size:=24,tint:Color=T.PAPER) -> void:inter_stack.add_child(_label(text,size,tint))

func _inter_button(text:String,callback:Callable,disabled:=false) -> Button:
    var button:=Button.new();button.text=text;button.custom_minimum_size=Vector2(0,48)
    button.add_theme_font_size_override("font_size",24);button.disabled=disabled;button.pressed.connect(callback);inter_stack.add_child(button)
    return button

func _row_button(row:HBoxContainer,text:String,callback:Callable,disabled:=false) -> void:
    var button:=Button.new();button.text=text;button.custom_minimum_size=Vector2(0,66);button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    button.add_theme_font_size_override("font_size",22);button.disabled=disabled;button.pressed.connect(callback);row.add_child(button)

func _build_inter() -> void:
    for child in inter_stack.get_children():
        inter_stack.remove_child(child);child.queue_free()
    var p=campaign.profile;var d:Dictionary=p.data;var run:Dictionary=d.run
    var kind:String=inter_info.kind
    _inter_text(inter_info.title,32,T.TEAL)
    for line in d.last_loot:_inter_text(str(line),24,T.LIME)
    if run.is_empty():
        _inter_text("CREDITS %d   PARTS %d   CHAIN x%d"%[int(d.credits),int(d.parts),streak],24,T.MUTED)
    else:
        _inter_text("HP %d   METER %d   CREDITS %d   CHAIN x%d"%[int(run.hp),int(run.meter),int(d.credits),streak],24,T.MUTED)
    if kind=="win" and not run.is_empty() and run.get("mode","story")=="story" and int(run.room)<18:
        var line:Dictionary=Lines.render(Lines.encounter(int(run.room)),int(run.hero))
        _inter_text("NEXT / %s %d OF 3 / %s"%[p.DISTRICTS[Lines.chapter_of(int(run.room))],int(run.room)%3+1,("BOSS" if int(run.room) in [11,17] else "PATROL")],24,T.GOLD)
        _inter_text("%s: %s"%[line.speaker,line.text],24,Color(str(line.color)))
    elif kind=="contract_next":
        _inter_text("A same-tier contract is ready. Keep the chain going or bank it at home.",24)
    if not run.is_empty() and bool(run.boon_due):
        _inter_text("TAKE ONE CURRENT   (ENTER = DEFAULT)",24,T.TEAL)
        var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);inter_stack.add_child(row)
        var number:=1
        for id in ["damage","defence","economy"]:
            var stat:String=id;var gain:float=p.boon_gain(stat)
            _row_button(row,"%d  +%d%%\n%s"%[number,roundi(gain*100),stat.to_upper()],func():_pick_boon(stat),gain<=0);number+=1
        _row_button(row,"0  +10\nCREDITS",func():_pick_credits())
    if not run.is_empty() and bool(run.get("route_due",false)):
        _inter_text("CHOOSE THE NEXT ROUTE   (ENTER = COMBAT)",24,T.TEAL)
        var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);inter_stack.add_child(row)
        var key:=4
        for route in p.route_options():
            var id:String=route
            _row_button(row,"%d  %s"%[key,{"combat":"COMBAT\nnormal loot","cache":"SALVAGE\n+1 item, heavy foe","hazard":"CHARGED\n+20% credits","rest":"REST\n+20 HP once"}[route]],func():_pick_route(id));key+=1
    var go:String={"win":"NEXT ENCOUNTER","retry":"RETRY THE WAVE","contract_next":"NEXT CONTRACT"}[kind]
    var main:=_inter_button(go+" / ENTER",_continue)
    _inter_button("RETURN TO SAFE BLOCK / ESC",_home)
    main.grab_focus()
    hint_label.text="CHAIN x%d    ENTER: KEEP GOING    ESC: GO HOME"%streak

func _pick_boon(id:String) -> void:
    if campaign.profile.choose_boon(id):_build_inter()

func _pick_credits() -> void:
    if campaign.profile.skip_boon():_build_inter()

func _pick_route(id:String) -> void:
    if campaign.profile.choose_route(id):_build_inter()

func _default_choices() -> bool:
    var p=campaign.profile;var run:Dictionary=p.data.run
    if run.is_empty():return true
    if bool(run.boon_due):
        var done:=false
        for id in ["damage","defence","economy"]:
            if p.boon_gain(id)>0 and p.choose_boon(id):done=true;break
        if not done and not p.skip_boon():return false
    if bool(run.get("route_due",false)) and not p.choose_route("combat"):return false
    return true

func _continue() -> void:
    if mode!="inter":return
    var p=campaign.profile
    if not _default_choices():_build_inter();return
    var kind:String=inter_info.kind
    if kind=="contract_next":
        if not p.start_contract(campaign.hero_id(),int(inter_info.contract)):_build_inter();return
    _hide_all()
    campaign.session.return_to_title()
    campaign.depart()

func _home() -> void:
    if mode!="inter":return
    _hide_all();streak=0;campaign.show_city()

# ---------------------------------------------------------------- frame / input
func _process(delta:float) -> void:
    if mode=="cards" and not queue.is_empty():
        typed+=delta*70.0
        if typed!=INF:text_label.visible_characters=mini(L10n.text(text_label.text).length(),floori(typed))
    if caption.visible:
        caption_left-=delta
        if caption_left<=0 or not campaign.active:caption.visible=false
    if mode=="" and live() and campaign.active and campaign.lesson_active=="" and campaign.session.screen=="result" and campaign.encounter_finished() and campaign.session.sim.story_state=="complete" and not campaign.settlement_done:
        auto_clock+=delta
        if auto_clock>=1.1:auto_clock=0.0;campaign.return_from_encounter()
    elif mode=="":auto_clock=0.0

func _unhandled_key_input(event:InputEvent) -> void:
    if mode=="" or not event.is_pressed() or event.is_echo():return
    var key:Key=event.keycode
    if mode=="cards":
        if key in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:_advance_card()
        elif key==KEY_ESCAPE:skip_cards()
        get_viewport().set_input_as_handled();return
    if key in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:_continue()
    elif key==KEY_ESCAPE:_home()
    elif key in [KEY_1,KEY_2,KEY_3]:_pick_boon(["damage","defence","economy"][key-KEY_1])
    elif key==KEY_0:_pick_credits()
    elif key in [KEY_4,KEY_5,KEY_6]:
        var options:Array=campaign.profile.route_options();var index:int=key-KEY_4
        if index<options.size():_pick_route(str(options[index]))
    get_viewport().set_input_as_handled()

func _input(event:InputEvent) -> void:
    if mode=="cards" and event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
        _advance_card();get_viewport().set_input_as_handled()
