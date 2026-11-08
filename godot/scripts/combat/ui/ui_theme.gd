extends RefCounted
## Shared native Godot UI tokens. See DESIGN.md and UX-CONTRACT.md.
const INK := Color("102c34")
const NIGHT := Color("0a2028")
const PAPER := Color("f4ead8")
const MUTED := Color("aec3c5")
const TEAL := Color("57dfcc")
const CORAL := Color("ff785d")
const GOLD := Color("eebd4c")
const EDGE := Color("48636a")
const BODY = preload("res://assets/fonts/AfterhoursUIHK.otf")
const DISPLAY = preload("res://assets/fonts/DejaVuSansCondensed-Bold.ttf")
static func plate(color: Color, border := Color.TRANSPARENT, width := 0) -> StyleBoxFlat:
    var style:=StyleBoxFlat.new()
    style.bg_color=color
    style.border_color=border
    style.set_border_width_all(width)
    style.content_margin_left=18
    style.content_margin_right=18
    style.content_margin_top=8
    style.content_margin_bottom=8
    return style
static func build() -> Theme:
    var theme:=Theme.new()
    theme.default_font=BODY
    theme.default_font_size=17
    theme.set_color("font_color","Label",PAPER)
    for type_name in ["Button","OptionButton","CheckButton","PopupMenu"]:
        theme.set_color("font_color",type_name,PAPER)
        theme.set_color("font_hover_color",type_name,INK)
        theme.set_color("font_focus_color",type_name,PAPER)
        theme.set_color("font_disabled_color",type_name,MUTED.darkened(.2))
        theme.set_stylebox("normal",type_name,plate(INK,EDGE,1))
        theme.set_stylebox("hover",type_name,plate(TEAL,TEAL,1))
        theme.set_stylebox("pressed",type_name,plate(GOLD,GOLD,1))
        theme.set_stylebox("disabled",type_name,plate(NIGHT,EDGE.darkened(.3),1))
        theme.set_stylebox("focus",type_name,plate(Color.TRANSPARENT,PAPER,2))
    theme.set_color("font_pressed_color","Button",INK)
    theme.set_stylebox("panel","PopupMenu",plate(NIGHT,TEAL,1))
    theme.set_color("font_hover_color","PopupMenu",INK)
    theme.set_stylebox("hover","PopupMenu",plate(TEAL))
    theme.set_stylebox("scroll","VScrollBar",plate(NIGHT))
    theme.set_stylebox("grabber","VScrollBar",plate(EDGE))
    theme.set_stylebox("grabber_highlight","VScrollBar",plate(TEAL))
    theme.set_stylebox("grabber_pressed","VScrollBar",plate(GOLD))
    theme.set_constant("scrollbar_width","VScrollBar",9)
    theme.set_stylebox("slider","HSlider",plate(EDGE))
    theme.set_stylebox("grabber_area","HSlider",plate(TEAL))
    theme.set_stylebox("grabber_area_highlight","HSlider",plate(GOLD))
    return theme
