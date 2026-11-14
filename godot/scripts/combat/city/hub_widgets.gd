extends RefCounted
## Picture-first building blocks for the hub pages. Tiles carry an icon, a one-word title and a one-word state;
## longer explanations go to the info line under the panel so the page itself stays readable at a glance.
const T=preload("res://scripts/combat/ui/ui_theme.gd")
const Icons=preload("res://scripts/combat/city/ui_icons.gd")
const DIM:=Color("0d0f13")

static func _style(state:String,tint:Color) -> StyleBoxFlat:
    var s:StyleBoxFlat=T.plate(T.NIGHT,T.EDGE,2)
    match state:
        "owned":s=T.plate(Color("06191c"),T.TEAL,3)
        "ready":s=T.plate(T.NIGHT,tint,3)
        "active":s=T.plate(T.INK,T.LIME,4)
        "locked":s=T.plate(DIM,T.EDGE,1)
    s.content_margin_left=6;s.content_margin_right=6;s.content_margin_top=6;s.content_margin_bottom=6
    return s

static func label(text:String,size:int=20,tint:Color=T.PAPER,center:=false,wrap:=true) -> Label:
    var l:=Label.new();l.text=text;l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_color",tint)
    l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF;l.mouse_filter=Control.MOUSE_FILTER_IGNORE
    if center:l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    return l

static func section(hub:Node,icon:String,text:String,tint:Color=T.TEAL) -> void:
    var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8)
    row.add_child(_small(icon,tint))
    var l:=label(text,22,tint);l.autowrap_mode=TextServer.AUTOWRAP_OFF;row.add_child(l)
    hub.stack.add_child(row)

static func head_title(hub:Node,text:String,tint:Color) -> void:
    var l:=label(text,28,tint);hub.stack.add_child(l)

static func _small(icon:String,tint:Color) -> TextureRect:
    var r:=Icons.rect(icon,tint,T.CORAL);r.custom_minimum_size=Vector2(28,28);return r

static func head(hub:Node,icon:String,title:String,tint:Color) -> void:
    var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10)
    row.add_child(Icons.rect(icon,tint,T.CORAL))
    var l:=label(title,32,tint);l.autowrap_mode=TextServer.AUTOWRAP_OFF;l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;row.add_child(l)
    var close:=Button.new();close.custom_minimum_size=Vector2(52,52);close.icon=Icons.texture("close",T.PAPER,T.CORAL);close.expand_icon=true
    close.tooltip_text="ESC";close.pressed.connect(hub.close_panel);close.set_meta("act","close");row.add_child(close)
    hub.stack.add_child(row)

## One card = button with children. state: ready (can act), owned (done), locked, active (selected), plain.
static func tile(hub:Node,icon:String,title:String,sub:String,tint:Color,state:String,callback:Callable,info:="",act:="",size:=Vector2(0,104),side:=false) -> Button:
    var b:=Button.new();b.custom_minimum_size=size;b.clip_contents=true;b.focus_mode=Control.FOCUS_ALL
    var base:=_style(state,tint)
    var hover:=_style(state,tint);hover.border_color=T.PAPER
    b.add_theme_stylebox_override("normal",base);b.add_theme_stylebox_override("hover",hover);b.add_theme_stylebox_override("focus",hover)
    b.add_theme_stylebox_override("pressed",hover);b.add_theme_stylebox_override("disabled",base)
    b.disabled=state=="locked" or state=="off"
    if state=="owned" and not callback.is_valid():b.disabled=true
    var box:BoxContainer
    if side:box=HBoxContainer.new()
    else:box=VBoxContainer.new()
    box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);box.mouse_filter=Control.MOUSE_FILTER_IGNORE
    box.alignment=BoxContainer.ALIGNMENT_CENTER;box.add_theme_constant_override("separation",4 if side else 0);b.add_child(box)
    var pic:=Icons.rect("lock" if state=="locked" else icon,tint if state!="locked" else T.MUTED,T.CORAL)
    if side:pic.custom_minimum_size=Vector2(40,40)
    pic.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;box.add_child(pic)
    var words:BoxContainer=VBoxContainer.new() if side else box
    if side:words.mouse_filter=Control.MOUSE_FILTER_IGNORE;words.alignment=BoxContainer.ALIGNMENT_CENTER;words.add_theme_constant_override("separation",0);box.add_child(words)
    if title!="":words.add_child(label(title,20,T.PAPER if state!="locked" else T.MUTED,not side,false))
    if sub!="":words.add_child(label(sub,18,tint if state=="ready" else (T.TEAL if state=="owned" else T.MUTED),not side,false))
    if callback.is_valid():b.pressed.connect(callback)
    if act!="":b.set_meta("act",act)
    if info!="":
        b.mouse_entered.connect(hub.set_info.bind(info));b.focus_entered.connect(hub.set_info.bind(info))
    b.tooltip_text=title
    hub.stack.add_child(b)
    return b

static func grid(hub:Node,columns:int=3) -> GridContainer:
    var g:=GridContainer.new();g.columns=columns;g.add_theme_constant_override("h_separation",8);g.add_theme_constant_override("v_separation",8)
    g.size_flags_horizontal=Control.SIZE_EXPAND_FILL;hub.stack.add_child(g)
    return g

## tile() adds to the stack; call this to move the just-created tile into a grid or row.
static func into(parent:Node,node:Control) -> Control:
    node.get_parent().remove_child(node);parent.add_child(node);node.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    return node

static func row(hub:Node,sep:int=8) -> HBoxContainer:
    var r:=HBoxContainer.new();r.add_theme_constant_override("separation",sep);r.size_flags_horizontal=Control.SIZE_EXPAND_FILL;hub.stack.add_child(r)
    return r

static func pips(hub:Node,states:Array,tint:Color=T.TEAL,parent:Node=null,gap:int=0) -> Control:
    ## states: 0 empty, 1 filled, 2 current. Groups of `gap` get a wider space.
    var c:=Control.new();c.custom_minimum_size=Vector2(maxi(1,states.size())*22+(floori(float(states.size())/maxf(1.0,gap))*10 if gap>0 else 0),24)
    c.mouse_filter=Control.MOUSE_FILTER_IGNORE
    c.draw.connect(func():
        var x:=0.0
        for i in states.size():
            if gap>0 and i>0 and i%gap==0:x+=10.0
            var col:Color=[T.EDGE,tint,T.LIME][int(states[i])]
            c.draw_rect(Rect2(x,2,18,18),T.INK);c.draw_rect(Rect2(x+2,4,14,14),col if int(states[i])>0 else Color("1a1d24"))
            x+=22.0)
    (parent if parent else hub.stack).add_child(c)
    return c

static func bar(hub:Node,value:float,maximum:float,tint:Color,icon:String,parent:Node=null) -> Control:
    var r:=HBoxContainer.new();r.add_theme_constant_override("separation",6);r.mouse_filter=Control.MOUSE_FILTER_IGNORE
    var pic:=Icons.rect(icon,tint,T.CORAL);pic.custom_minimum_size=Vector2(28,28);pic.size_flags_vertical=Control.SIZE_SHRINK_CENTER;r.add_child(pic)
    var c:=Control.new();c.custom_minimum_size=Vector2(90,24);c.size_flags_horizontal=Control.SIZE_EXPAND_FILL;c.mouse_filter=Control.MOUSE_FILTER_IGNORE
    c.draw.connect(func():
        c.draw_rect(Rect2(0,2,c.size.x,20),T.INK);c.draw_rect(Rect2(3,5,c.size.x-6,14),Color("1a1d24"))
        c.draw_rect(Rect2(3,5,(c.size.x-6)*clampf(value/maxf(1.0,maximum),0,1),14),tint))
    r.add_child(c);r.add_child(label(str(roundi(value)),20,T.PAPER,false,false))
    (parent if parent else hub.stack).add_child(r)
    return r

static func chip(icon:String,text:String,tint:Color=T.PAPER,parent:Node=null) -> Control:
    var r:=HBoxContainer.new();r.add_theme_constant_override("separation",4);r.mouse_filter=Control.MOUSE_FILTER_IGNORE
    var pic:=Icons.rect(icon,tint,T.CORAL);pic.custom_minimum_size=Vector2(24,24);pic.size_flags_vertical=Control.SIZE_SHRINK_CENTER;r.add_child(pic)
    var l:=label(text,20,T.PAPER);l.autowrap_mode=TextServer.AUTOWRAP_OFF;r.add_child(l)
    if parent:parent.add_child(r)
    return r

## Wide call-to-action button with an icon on the left.
static func cta(hub:Node,icon:String,text:String,tint:Color,callback:Callable,disabled:=false,act:="",info:="") -> Button:
    var b:=Button.new();b.custom_minimum_size=Vector2(0,64);b.disabled=disabled
    var s:=T.plate(tint,T.PAPER,3);s.content_margin_left=12
    b.add_theme_stylebox_override("normal",s)
    var h:=T.plate(tint.lightened(.25),T.PAPER,4);b.add_theme_stylebox_override("hover",h);b.add_theme_stylebox_override("focus",h)
    b.add_theme_stylebox_override("disabled",T.plate(DIM,T.EDGE,1))
    b.add_theme_color_override("font_color",T.INK);b.add_theme_color_override("font_hover_color",T.INK);b.add_theme_color_override("font_focus_color",T.INK);b.add_theme_color_override("font_disabled_color",T.EDGE)
    b.add_theme_constant_override("outline_size",0)
    b.add_theme_font_size_override("font_size",32);b.text=text;b.icon=Icons.texture(icon,T.INK,T.PAPER);b.expand_icon=true;b.add_theme_constant_override("icon_max_width",40)
    b.pressed.connect(callback)
    if act!="":b.set_meta("act",act)
    if info!="":b.mouse_entered.connect(hub.set_info.bind(info));b.focus_entered.connect(hub.set_info.bind(info))
    hub.stack.add_child(b)
    return b

## Stat vocabulary shared by gear and talent pages: one icon and one short word per stat.
const STAT_ICON:={"damage":"swords","heavy_damage":"fist","guard_damage":"shield","finisher_damage":"finisher","launch_force":"launcher","chain_damage":"ring","aerial_damage":"double_jump","counter_damage":"swords","defence":"shield","economy":"bolt","parry_meter":"bolt","entry":"bolt","chain_meter":"bolt","chase_refund":"chase","chain_targets":"ring","splash":"ring","pile_driver":"fist","sky_commitment":"double_jump","patient_storm":"shield","broadcaster":"radio"}
const STAT_SHORT:={"damage":"DMG","heavy_damage":"HEAVY","guard_damage":"GUARD","finisher_damage":"SLAM","launch_force":"LAUNCH","chain_damage":"CHAIN","aerial_damage":"AIR","counter_damage":"COUNTER","defence":"DEF","economy":"SAVE","parry_meter":"PARRY","entry":"START","chain_meter":"CHAIN","chase_refund":"CHASE","chain_targets":"TARGET","splash":"SPLASH"}
const FLAT_STATS:=["entry","parry_meter","chain_targets","splash","chain_meter","chase_refund"]

static func stat_text(stat:String,amount:float) -> String:
    return "%+d"%roundi(amount) if stat in FLAT_STATS else "%+d%%"%roundi(amount*100)

## Icon + value, lime when it helps, pink when it costs.
static func stat_chip(stat:String,amount:float,parent:Node=null,with_word:=true) -> Control:
    var tint:Color=T.LIME if amount>=0 else T.CORAL
    var text:=stat_text(stat,amount)
    if with_word:text=STAT_SHORT.get(stat,stat.to_upper())+" "+text
    return chip(STAT_ICON.get(stat,"star"),text,tint,parent)
