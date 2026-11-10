extends Control
## Compact companion to the fight UI; the street remains the main view.
const Tokens=preload("res://scripts/combat/ui/ui_theme.gd")
var copy=preload("res://scripts/combat/ui/ui_text.gd").new()
var session: Node3D
var expanded:=false
var back_button: Button
var layout: Control
func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    theme=Tokens.build()
    layout=Control.new()
    layout.mouse_filter=Control.MOUSE_FILTER_IGNORE
    add_child(layout)
    back_button=Button.new()
    back_button.position=Vector2(1010,24)
    back_button.size=Vector2(246,44)
    back_button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
    back_button.pressed.connect(session.return_to_fight)
    layout.add_child(back_button)
    resized.connect(_resize)
    _resize()
    refresh()
func _resize() -> void:
    if is_instance_valid(layout):layout.scale=size/Vector2(1280,720)
func refresh() -> void:
    if is_instance_valid(back_button):back_button.text=copy.text("back_fight")
    queue_redraw()
func _text(at: Vector2, value: String, point_size: int, color := Tokens.PAPER) -> void:
    draw_string(Tokens.BODY,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,maxi(Tokens.CAPTION_SIZE,point_size),color)
func _plate(at: Vector2, panel_size: Vector2) -> void:
    draw_rect(Rect2(at,panel_size),Color(Tokens.NIGHT,.94))
    draw_rect(Rect2(at,panel_size),Tokens.EDGE,false,1)
func _draw() -> void:
    if not is_instance_valid(session):return
    draw_set_transform(Vector2.ZERO,0,size/Vector2(1280,720))
    var mode:=copy.text("first_person" if session.player.first_person else "third_person")
    if not session.walking:mode=copy.text("reference_view")+" %02d"%(session.street.active_view+1)
    var style_key: String=["style_original","style_two","style_three"][session.get_node("StyleSample").mode]
    var style=session.get_node("StyleSample")
    var sky_key:="sky_image" if style.image_sky_enabled else ("sky_cloud" if style.clouds_enabled else "sky_flat")
    _plate(Vector2(24,24),Vector2(650,83))
    _text(Vector2(42,57),copy.text("walk_title")+" / "+mode,22,Tokens.TEAL)
    _text(Vector2(42,86),"B "+copy.text(style_key)+"     N "+copy.text(sky_key),14,Tokens.MUTED)
    if session.options.get("muted",false):_text(Vector2(1010,98),copy.text("muted"),14,Tokens.GOLD)
    if expanded:
        _plate(Vector2(24,501),Vector2(1232,195))
        _text(Vector2(42,533),copy.text("walk_help"),20,Tokens.TEAL)
        _text(Vector2(42,568),copy.text("walk_hint"),17)
        _text(Vector2(42,601),copy.text("walk_views"),17)
        _text(Vector2(42,634),copy.text("walk_tools"),17)
        _text(Vector2(42,674),copy.text("walk_mouse"),14,Tokens.MUTED)
    else:
        _plate(Vector2(24,626),Vector2(1232,70))
        _text(Vector2(42,654),copy.text("walk_hint"),17)
        _text(Vector2(42,680),copy.text("walk_mouse"),14,Tokens.MUTED)
