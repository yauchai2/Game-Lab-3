extends Control
const T=preload("res://scripts/combat/ui/ui_theme.gd")
const Icons=preload("res://scripts/combat/city/ui_icons.gd")
const Builds=preload("res://scripts/combat/city/city_builds.gd")
const W=preload("res://scripts/combat/city/hub_widgets.gd")
const BRANCH_ICON=["fist","launcher","shield","circuit"]
const HEROES=["ZIP","RIVET","HUSH","LOOP"]
var profile:RefCounted
var hero:=0
var selected:=""
var board:Control
var detail:VBoxContainer
var topbar:HBoxContainer
var stack:VBoxContainer ## same contract as the hub, so hub_widgets cards can be built here
var footer:Label
var zoom:=.68
var pan:=Vector2(420,260)
var dragging:=false
var buttons:Dictionary={}
const COLORS=[Color("ff008c"),Color("00cbd9"),Color("ffd24b"),Color("c5ef33")]
func _ready() -> void:
    size=Vector2(1280,720);mouse_filter=Control.MOUSE_FILTER_STOP
    var background:=ColorRect.new();background.color=Color("101220");background.size=size;background.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(background)
    topbar=HBoxContainer.new();topbar.position=Vector2(30,18);topbar.size=Vector2(860,48);topbar.add_theme_constant_override("separation",22);add_child(topbar)
    board=Control.new();board.position=Vector2(24,112);board.size=Vector2(850,520);board.clip_contents=true
    board.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;board.gui_input.connect(_board_input);board.draw.connect(_draw_board);add_child(board)
    detail=VBoxContainer.new();stack=detail;detail.position=Vector2(906,116);detail.size=Vector2(340,510);detail.add_theme_constant_override("separation",13);add_child(detail)
    footer=Label.new();footer.position=Vector2(30,646);footer.size=Vector2(1220,60);footer.add_theme_font_size_override("font_size",24);footer.add_theme_color_override("font_color",T.MUTED);footer.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(footer)
    for index in 3:
        var i:=index;var b:=Button.new();b.position=Vector2(912+i*108,38);b.size=Vector2(100,45);b.text=["-","+","FIT"][i];b.tooltip_text=["ZOOM OUT","ZOOM IN","FIT"][i]
        b.pressed.connect(func():
            if i==2:zoom=.68;pan=Vector2(420,260)
            else:zoom=clampf(zoom*(1.25 if i==1 else .8),.4,2.2)
            _positions());add_child(b)
    hide()
func open(p:RefCounted,hero_id:int) -> void:
    profile=p;hero=hero_id;selected="hub_%d"%hero
    show();_rebuild()
func _rebuild() -> void:
    for child in board.get_children():board.remove_child(child);child.queue_free()
    buttons.clear()
    for node in Builds.nodes():
        var id:String=node.id;var b:=Button.new();b.name=id;b.flat=true;b.tooltip_text=node.name+"\n"+Builds.describe(node)
        for state in ["normal","hover","pressed","focus","disabled"]:b.add_theme_stylebox_override(state,StyleBoxEmpty.new())
        b.pressed.connect(func():selected=id;_detail();board.queue_redraw())
        b.focus_entered.connect(func():selected=id;_detail();board.queue_redraw())
        board.add_child(b);buttons[id]=b
    _positions();_detail()
func _positions() -> void:
    for node in Builds.nodes():
        var radius:=16.0 if node.kind in ["hub","keystone"] else 11.0
        buttons[node.id].position=pan+node.at*zoom-Vector2.ONE*radius
        buttons[node.id].size=Vector2.ONE*radius*2
    board.queue_redraw()
func _draw_board() -> void:
    board.draw_rect(Rect2(Vector2.ZERO,board.size),Color("171a2b"))
    if profile==null:return
    var allocated:Array=profile.data.talents[hero]
    for node in Builds.nodes():
        var at:Vector2=pan+node.at*zoom
        for id in node.links:
            var other:Dictionary=Builds.by_id(id)
            if other.is_empty():continue
            var live:bool=(node.id in allocated and (id in allocated or id=="hub_%d"%hero))
            board.draw_line(at,pan+other.at*zoom,COLORS[int(node.branch)] if live else Color("44475d"),3 if live else 2)
    for node in Builds.nodes():
        var at:Vector2=pan+node.at*zoom
        var owned:bool=node.id in allocated or node.id=="hub_%d"%hero
        var available:bool=allocated.size()<int(profile.data.points) and Builds.connected(hero,node.id,allocated)
        var radius:=15.0 if node.kind in ["hub","keystone"] else (12.0 if node.kind=="notable" else 8.0)
        board.draw_circle(at,radius+3,Color.WHITE if selected==node.id else (COLORS[int(node.branch)] if owned or available else Color("4f5266")))
        board.draw_circle(at,radius,COLORS[int(node.branch)] if owned else Color("10121e"))
        if node.kind in ["keystone","hub"]:board.draw_texture_rect(Icons.texture(BRANCH_ICON[int(node.branch)] if node.kind=="keystone" else "hero",Color("10121e") if owned else COLORS[int(node.branch)],Color.WHITE),Rect2(at-Vector2(12,12),Vector2(24,24)),false)
func set_info(text:String) -> void:
    if is_instance_valid(footer):footer.text=text
func close_panel() -> void:hide()
func _detail() -> void:
    for child in detail.get_children():detail.remove_child(child);child.queue_free()
    var node:Dictionary=Builds.by_id(selected);var allocated:Array=profile.data.talents[hero]
    var tint:Color=COLORS[int(node.branch)]
    for child in topbar.get_children():topbar.remove_child(child);child.queue_free()
    W.chip("hero",HEROES[hero],COLORS[hero],topbar);W.chip("star","LV%d"%profile.level(),T.PAPER,topbar)
    W.chip("circuit","%d/%d"%[allocated.size(),int(profile.data.points)],T.CORAL,topbar)
    var keys:=0
    for id in allocated:
        if Builds.by_id(id).get("kind","")=="keystone":keys+=1
    W.chip("flag","%d/1"%keys,T.LIME if keys==0 else T.MUTED,topbar)
    var head:=HBoxContainer.new();head.add_theme_constant_override("separation",10);detail.add_child(head)
    var pic:=Icons.rect(BRANCH_ICON[int(node.branch)] if node.kind!="hub" else "hero",tint,T.CORAL);pic.custom_minimum_size=Vector2(56,56);head.add_child(pic)
    var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",0);head.add_child(words)
    words.add_child(W.label(str(node.name).to_upper(),26,tint))
    words.add_child(W.label(str(node.kind).to_upper()+" / "+Builds.BRANCHES[int(node.branch)],18,T.MUTED,false,false))
    if node.kind!="hub":
        if node.kind=="keystone":W.chip("star","KEYSTONE",T.LIME,detail)
        else:W.stat_chip(str(node.stat),float(node.amount),detail)
    var can_buy:bool=allocated.size()<int(profile.data.points) and Builds.connected(hero,selected,allocated)
    var now:Dictionary=profile.stats(hero)
    var after:Dictionary=now
    if can_buy:
        profile.data.talents[hero].append(selected)
        after=profile.stats(hero);profile.data.talents[hero].pop_back()
    var totals:=HBoxContainer.new();totals.add_theme_constant_override("separation",10);totals.size_flags_horizontal=Control.SIZE_EXPAND_FILL;detail.add_child(totals)
    for key in ["damage","defence","economy"]:
        var card:=PanelContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.add_theme_stylebox_override("panel",T.plate(Color("10121f"),T.EDGE,2));totals.add_child(card)
        var cell:=VBoxContainer.new();cell.add_theme_constant_override("separation",0);card.add_child(cell)
        var icon:=Icons.rect(W.STAT_ICON[key],T.TEAL,T.CORAL);icon.custom_minimum_size=Vector2(32,32);icon.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;cell.add_child(icon)
        cell.add_child(W.label(W.stat_text(key,float(now[key])),22,T.PAPER,true,false))
        var gain:=roundi((float(after[key])-float(now[key]))*100)
        cell.add_child(W.label(("> %+d%%"%roundi(float(after[key])*100)) if gain!=0 else " ",20,T.LIME,true,false))
    var owned:bool=selected in allocated or node.kind=="hub"
    var buy:=W.row(self)
    var go:=W.cta(self,"check","OWNED" if owned else "CONNECT",tint,func():profile.allocate(hero,selected);_rebuild(),not can_buy,"connect","Spend one point to connect this node.")
    W.into(buy,go);W.chip("circuit","1",T.CORAL,buy)
    var tools:=W.row(self)
    var reset:=Button.new();reset.icon=Icons.texture("trash",T.PAPER,T.CORAL);reset.expand_icon=true;reset.custom_minimum_size=Vector2(0,52);reset.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    reset.tooltip_text="FREE RESET";reset.set_meta("act","reset");reset.pressed.connect(func():profile.respec(hero);_rebuild());reset.mouse_entered.connect(set_info.bind("Free reset: take back every point for this hero."));tools.add_child(reset)
    var close:=Button.new();close.icon=Icons.texture("close",T.PAPER,T.CORAL);close.expand_icon=true;close.custom_minimum_size=Vector2(0,52);close.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    close.tooltip_text="ESC";close.set_meta("act","close");close.pressed.connect(hide);tools.add_child(close)
    var text:=("Free gateway. Choose connected paths." if node.kind=="hub" else Builds.describe(node))
    if profile.error!="":text=profile.error
    set_info(text)
func _board_input(event:InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index==MOUSE_BUTTON_RIGHT:dragging=event.pressed;accept_event()
        elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
            var old:=zoom;zoom=clampf(zoom*(1.15 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.0/1.15),.4,2.2)
            pan=event.position-(event.position-pan)*(zoom/old);_positions();accept_event()
    elif event is InputEventMouseMotion and dragging:pan+=event.relative;_positions();accept_event()
