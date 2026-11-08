extends Control
var session: Node3D
var menu: CenterContainer
var menu_scroll: ScrollContainer
var notice := ""
var notice_time := 0.0
var font: Font
var bold: Font
var vfx_renderer := preload("res://scripts/combat/fight_vfx.gd").new()
const INK := Color("121a2d")
const PAPER := Color("f4efda")
const YELLOW := Color("eaf078")

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    font = ThemeDB.fallback_font
    var system := SystemFont.new()
    system.font_names = PackedStringArray(["DejaVu Sans", "sans-serif"])
    system.font_weight = 800
    bold = system
    menu = CenterContainer.new()
    menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(menu)
    rebuild_menu()

func rebuild_menu() -> void:
    for child in menu.get_children():
        menu.remove_child(child)
        child.queue_free()
    if session.screen == "play":
        return
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(420,0)
    var style := StyleBoxFlat.new()
    style.bg_color = INK
    style.border_color = YELLOW
    style.set_border_width_all(2)
    style.content_margin_left = 28
    style.content_margin_right = 28
    style.content_margin_top = 24
    style.content_margin_bottom = 24
    panel.add_theme_stylebox_override("panel", style)
    menu_scroll = ScrollContainer.new()
    menu_scroll.custom_minimum_size=Vector2(420,clampf(get_viewport_rect().size.y-144,280,560))
    menu_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
    menu_scroll.follow_focus=true
    panel.add_child(menu_scroll)
    var stack := VBoxContainer.new()
    stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    stack.add_theme_constant_override("separation", 12)
    menu_scroll.add_child(stack)
    menu.add_child(panel)
    var title := "STEP INTO THE CIRCLE"
    if session.screen == "title":
        title = "AFTERHOURS"
    elif session.screen == "pause":
        title = "TAKE A BREATHER"
    elif session.screen == "result":
        title = "DRAW" if session.sim.winner < 0 else ("YOU WIN" if session.sim.winner == 0 else "RIVAL WINS")
    var heading := Label.new()
    heading.text = title
    heading.add_theme_color_override("font_color", YELLOW)
    heading.add_theme_font_size_override("font_size", 30)
    heading.add_theme_font_override("font", bold)
    stack.add_child(heading)
    var sub := Label.new()
    sub.text = "TRAINING / UNLIMITED TIME & ENERGY" if session.practice and session.screen!="title" else "STREET FIGHT / FIRST TO 2 ROUNDS"
    sub.add_theme_font_size_override("font_size", 13)
    stack.add_child(sub)
    var help := Label.new()
    help.text = "A / D     Move        SPACE     Jump\nJ             Light / 3-hit chain\nK            Heavy     W + K     Launcher\nL             Special (50 energy)\nSHIFT    Guard / timed parry\nE             Dodge\nESC        Pause       F6           Explore street\nOn launcher hit: SPACE, then J"
    help.add_theme_color_override("font_color", PAPER)
    help.add_theme_font_size_override("font_size", 15)
    stack.add_child(help)
    if session.screen == "title":
        _button(stack,"FIGHT THE RIVAL  /  ENTER",func(): session.start_match(false),true)
        _button(stack,"TRAINING  /  T",func(): session.start_match(true))
    elif session.screen == "pause":
        _button(stack,"BACK TO THE FIGHT",func(): session.resume_game(),true)
        _button(stack,"RESET TRAINING  /  F5" if session.practice else "RESTART MATCH",func(): session.reset_training() if session.practice else session.start_match(false))
        _button(stack,"MAIN MENU",func(): session.return_to_title())
    elif session.screen == "result":
        var result := Label.new()
        result.text = "%d : %d   /   %s" % [session.sim.wins[0],session.sim.wins[1],"MATCH COMPLETE" if session.sim.phase == "match_over" else "ROUND COMPLETE"]
        result.add_theme_color_override("font_color", PAPER)
        stack.add_child(result)
        _button(stack,"REMATCH  /  ENTER" if session.sim.phase == "match_over" else "NEXT ROUND  /  ENTER",func():
            if session.sim.phase == "match_over": session.start_match(session.practice)
            else: session.advance_round(),true)
    if session.screen in ["title","pause"]:
        _choice(stack,"RIVAL DIFFICULTY",["RELAXED","STANDARD","CHALLENGING"],session.sim.difficulty,session.set_difficulty)
        if session.practice or session.screen=="title":
            _choice(stack,"TRAINING PARTNER / F7",["STANDING","GUARDING","SPARRING"],session.sim.partner_mode,session.set_partner_mode)
    _button(stack,"SOUND: %s  /  M" % ("OFF" if session.audio.muted else "ON"),func():
        session.audio.muted = not session.audio.muted
        session.audio.stop_all()
        session.save_options()
        rebuild_menu())
    _button(stack,"REDUCED FLASH & SHAKE: %s  /  F2" % ("ON" if session.reduced_effects else "OFF"),func():
        session.reduced_effects = not session.reduced_effects
        session.save_options()
        rebuild_menu())
    _button(stack,"MUSIC: %s  /  F4" % ("OFF" if session.audio.music_muted else "ON"),func():
        session.audio.music_muted = not session.audio.music_muted
        session.save_options()
        rebuild_menu())
    _button(stack,"SCENE EDGES: %s  /  O" % ("ON" if session.ink_pass.visible else "OFF"),func():
        session.ink_pass.visible = not session.ink_pass.visible
        session.save_options()
        rebuild_menu())
    _button(stack,"EXPLORE THE STREET  /  F6",func(): session.return_to_street())
    for child in stack.get_children():
        if child is Button:
            call_deferred("_focus_button", child)
            break

func _choice(parent: Node, label: String, items: Array, selected: int, callback: Callable) -> void:
    var caption := Label.new()
    caption.text=label
    caption.add_theme_font_size_override("font_size",12)
    caption.add_theme_color_override("font_color",Color("a6b0c0"))
    parent.add_child(caption)
    var choice := OptionButton.new()
    choice.custom_minimum_size.y=40
    for item in items: choice.add_item(item)
    choice.select(selected)
    choice.item_selected.connect(callback)
    parent.add_child(choice)

func _focus_button(button: Node) -> void:
    if is_instance_valid(button) and button.is_inside_tree():
        button.grab_focus()

func _button(parent: Node, text: String, callback: Callable, primary := false) -> void:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size.y = 40
    button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    button.add_theme_font_size_override("font_size", 13)
    var normal := StyleBoxFlat.new()
    normal.bg_color = YELLOW if primary else Color("263248")
    normal.content_margin_left = 12
    normal.content_margin_right = 12
    button.add_theme_stylebox_override("normal",normal)
    var hover: StyleBoxFlat = normal.duplicate()
    hover.bg_color = Color("fbffa2") if primary else Color("40516a")
    button.add_theme_stylebox_override("hover",hover)
    var pressed: StyleBoxFlat = normal.duplicate()
    pressed.bg_color = Color("83cfc0")
    button.add_theme_stylebox_override("pressed",pressed)
    var focus := StyleBoxFlat.new()
    focus.bg_color = Color.TRANSPARENT
    focus.border_color = Color.WHITE
    focus.set_border_width_all(3)
    button.add_theme_stylebox_override("focus",focus)
    button.add_theme_color_override("font_color", INK if primary else PAPER)
    button.add_theme_color_override("font_hover_color", INK if primary else PAPER)
    button.add_theme_color_override("font_focus_color", INK if primary else PAPER)
    button.pressed.connect(callback)
    parent.add_child(button)

func _process(delta: float) -> void:
    notice_time = maxf(0.0, notice_time-delta)

func _text(at: Vector2, value: String, font_size: int, color := PAPER, heavy := false) -> void:
    draw_string(bold if heavy else font, at, value, HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func _rect(at: Vector2, extent: Vector2, color: Color) -> void:
    draw_rect(Rect2(at,extent),color)

func _draw() -> void:
    if not is_instance_valid(session):
        return
    draw_set_transform(Vector2.ZERO,0,size / Vector2(1280,720))
    for effect in session.effects:
        if effect.age >= 0:
            _effect(effect)
    var sim = session.sim
    var a: Dictionary = sim.fighters[0]
    var b: Dictionary = sim.fighters[1]
    _rect(Vector2.ZERO,Vector2(1280,96),Color(0.05,0.08,0.14,0.95))
    _text(Vector2(38,20),"AFTERHOURS",17,YELLOW,true)
    _text(Vector2(1010,20),"STREET FIGHT  /  PROTOTYPE",12,Color("a6b0c0"))
    _health(38,a,session.COLORS[0],false)
    _health(758,b,session.COLORS[1],true)
    _text(Vector2(38,39),"01 / YOU",15,session.COLORS[0],true)
    _text(Vector2(1050,39),"02 / RIVAL" if not session.practice else "02 / PRACTICE",15,session.COLORS[1],true)
    _rect(Vector2(592,16),Vector2(96,62),YELLOW)
    _text(Vector2(602 if session.practice else 611,60),"FREE" if session.practice else "%02d" % ceili(sim.remaining),28 if session.practice else 34,INK,true)
    _text(Vector2(600,94),"ROUND %02d" % sim.round_number,11,PAPER)
    for i in 2:
        for pip in 2:
            var at := Vector2(538+pip*20 if i==0 else 708+pip*20,30)
            draw_circle(at,6,session.COLORS[i] if sim.wins[i]>pip else Color("354354"))
    _rect(Vector2(0,660),Vector2(1280,60),INK)
    _text(Vector2(38,684),"J  LIGHT    K  HEAVY    W+K  LAUNCH    L  SPECIAL",14,PAPER,true)
    _text(Vector2(38,707),"A/D  MOVE     SPACE  JUMP     SHIFT  GUARD     E  DODGE",12,Color("9cabb8"))
    _text(Vector2(924,684),"ESC  PAUSE     F6  STREET",13,YELLOW)
    _text(Vector2(924,707),"M SOUND   F2 SOFT FX   O EDGES",12,Color("9cabb8"))
    if session.hitboxes_visible:
        _draw_hitboxes()
    if sim.combo_hits >= 2 and sim.fighters[1-sim.combo_owner].state == "stun":
        var x := 50.0 if sim.combo_owner == 0 else 1000.0
        _text(Vector2(x,204),"%02d HIT" % sim.combo_hits,42,YELLOW,true)
        _text(Vector2(x,230),"%d DAMAGE" % sim.combo_damage,15,PAPER)
    if sim.hitstop > 0:
        _rect(Vector2(492,620),Vector2(296,5),INK)
        _rect(Vector2(492,620),Vector2(296*float(sim.hitstop)/sim.hitstop_total,5),YELLOW)
        _text(Vector2(574,610),"IMPACT / BUFFER",12,YELLOW)
    if sim.phase == "ready" and session.screen == "play":
        _text(Vector2(460,300),"ROUND %02d" % sim.round_number,50,YELLOW,true)
        _text(Vector2(532,341),"GET READY",24,PAPER,true)
    if notice_time > 0:
        _rect(Vector2(446,554),Vector2(388,36),INK)
        _text(Vector2(464,579),notice,16,YELLOW)
    if session.screen != "play":
        _rect(Vector2(0,96),Vector2(1280,564),Color(0.025,0.04,0.08,0.72))
    if session.practice and session.screen == "play":
        _rect(Vector2(28,102),Vector2(500,52),Color(0.05,0.08,0.14,0.88))
        _rect(Vector2(956,102),Vector2(296,46+session.input_history.size()*18),Color(0.05,0.08,0.14,0.88))
        _text(Vector2(38,120),"TRAINING / %s / F5 RESET / F7 PARTNER" % ["STANDING","GUARDING","SPARRING"][sim.partner_mode],12,YELLOW)
        _text(Vector2(38,142),"LAST COMBO: %d HITS / %d DAMAGE" % [sim.last_combo_hits,sim.last_combo_damage],12,PAPER)
        _text(Vector2(1020,120),"INPUT HISTORY",12,YELLOW)
        for i in session.input_history.size():
            _text(Vector2(970,142+i*18),session.input_history[i],11,Color("bdcbd8"))

func _health(x: float, fighter: Dictionary, color: Color, reverse: bool) -> void:
    _rect(Vector2(x,46),Vector2(484,18),Color("334055"))
    var width: float = 484.0 * fighter.health / 100.0
    _rect(Vector2(x+484-width if reverse else x,46),Vector2(width,18),color)
    _text(Vector2(x+8,61),str(fighter.health),15,PAPER if reverse else INK,true)
    _rect(Vector2(x,71),Vector2(484,5),Color("334055"))
    _rect(Vector2(x,71),Vector2(484*fighter.meter/100.0,5),YELLOW)
    draw_line(Vector2(x+242,68),Vector2(x+242,79),PAPER,2)
    _text(Vector2(x,91),"ENERGY %03d  /  GUARD %03d" % [fighter.meter,fighter.guard],11,Color("a6b0c0"))
    if not reverse: _text(Vector2(x+350,91),"PARRY READY" if fighter.parry_cd==0 else "PARRY %.1fs" % (float(fighter.parry_cd)/60.0),10,Color("a6d8d1"))

func _effect(effect: Dictionary) -> void:
    vfx_renderer.draw_effect(self,session,effect)

func _draw_hitboxes() -> void:
    for i in 2:
        var f: Dictionary = session.sim.fighters[i]
        var foot: Vector2 = session.project(Vector2(f.x,f.y))
        var top: Vector2 = session.project(Vector2(f.x-0.35,f.y+2))
        draw_rect(Rect2(top,Vector2((foot.x-top.x)*2,foot.y-top.y)),Color(0,1,0,0.8),false,2)
        if f.state == "attack":
            var move: Dictionary = session.Simulation.MOVES[f.move]
            if f.frame >= move.startup and f.frame < move.startup + move.active:
                var end: Vector2 = session.project(Vector2(f.x+f.face*move.reach,f.y+1.2))
                draw_line(session.project(Vector2(f.x,f.y+1.2)),end,Color.RED,5)
