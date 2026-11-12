extends Control
const T=preload("res://scripts/combat/ui/ui_theme.gd")
const Builds=preload("res://scripts/combat/city/city_builds.gd")
var profile:RefCounted
var hero:=0
var selected:=""
var board:Control
var detail:VBoxContainer
var points:Label
var zoom:=.68
var pan:=Vector2(420,260)
var dragging:=false
var buttons:Dictionary={}
const COLORS=[Color("ff008c"),Color("00cbd9"),Color("ffd24b"),Color("c5ef33")]
func _ready() -> void:
    size=Vector2(1280,720);mouse_filter=Control.MOUSE_FILTER_STOP
    var background:=ColorRect.new();background.color=Color("101220");background.size=size;background.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(background)
    var title:=Label.new();title.text="CITY CIRCUIT / 48 NODES";title.position=Vector2(30,20);title.add_theme_font_size_override("font_size",32);add_child(title)
    points=Label.new();points.position=Vector2(30,63);points.add_theme_font_size_override("font_size",24);add_child(points)
    board=Control.new();board.position=Vector2(24,112);board.size=Vector2(850,520);board.clip_contents=true
    board.gui_input.connect(_board_input);board.draw.connect(_draw_board);add_child(board)
    detail=VBoxContainer.new();detail.position=Vector2(906,116);detail.size=Vector2(340,510);detail.add_theme_constant_override("separation",13);add_child(detail)
    var footer:=Label.new();footer.text="WHEEL: ZOOM / RIGHT DRAG: PAN / SELECT NODE TO INSPECT";footer.position=Vector2(30,653);footer.add_theme_font_size_override("font_size",24);add_child(footer)
    for index in 3:
        var i:=index;var b:=Button.new();b.position=Vector2(912+i*108,38);b.size=Vector2(100,45);b.text=["-","+","FIT"][i]
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
        if node.kind in ["keystone","hub"]:board.draw_string(T.BODY,at+Vector2(-7,6),"K" if node.kind=="keystone" else str(int(node.branch)+1),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("10121e") if owned else Color.WHITE)
func _label(text:String,color:Color=T.PAPER) -> void:
    var l:=Label.new();l.text=text;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",24);l.add_theme_color_override("font_color",color);detail.add_child(l)
func _button(text:String,callback:Callable,disabled:=false) -> void:
    var b:=Button.new();b.text=text;b.custom_minimum_size=Vector2(0,46);b.add_theme_font_size_override("font_size",24);b.disabled=disabled;b.pressed.connect(callback);detail.add_child(b)
func _detail() -> void:
    for child in detail.get_children():detail.remove_child(child);child.queue_free()
    var node:Dictionary=Builds.by_id(selected);var allocated:Array=profile.data.talents[hero]
    points.text="%s / LEVEL %d / %d OF %d POINTS / ONE KEYSTONE"%[["ZIP","RIVET","HUSH","LOOP"][hero],profile.level(),allocated.size(),int(profile.data.points)]
    _label(node.name,COLORS[int(node.branch)]);_label(str(node.kind).to_upper()+" / "+Builds.BRANCHES[int(node.branch)])
    _label("Character starting gateway. Free; choose connected paths." if node.kind=="hub" else Builds.describe(node))
    var can_buy:bool=allocated.size()<int(profile.data.points) and Builds.connected(hero,selected,allocated)
    var now:Dictionary=profile.stats(hero)
    _label("DAMAGE %+d%%\nDEFENCE %+d%%\nSKILL SAVING %+d%%"%[roundi(now.damage*100),roundi(now.defence*100),roundi(now.economy*100)])
    if can_buy:
        profile.data.talents[hero].append(selected)
        var after:Dictionary=profile.stats(hero);profile.data.talents[hero].pop_back()
        _label("AFTER: %+d%% / %+d%% / %+d%%"%[roundi(after.damage*100),roundi(after.defence*100),roundi(after.economy*100)],T.GOLD)
    _button("ALLOCATED" if selected in allocated else "CONNECT / 1 POINT",func():profile.allocate(hero,selected);_rebuild(),not can_buy)
    _button("FREE RESET CHARACTER",func():profile.respec(hero);_rebuild())
    _button("CLOSE / ESC",hide)
    if profile.error!="":_label(profile.error,T.GOLD)
func _board_input(event:InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index==MOUSE_BUTTON_RIGHT:dragging=event.pressed;accept_event()
        elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
            var old:=zoom;zoom=clampf(zoom*(1.15 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.0/1.15),.4,2.2)
            pan=event.position-(event.position-pan)*(zoom/old);_positions();accept_event()
    elif event is InputEventMouseMotion and dragging:pan+=event.relative;_positions();accept_event()
