extends RefCounted
## Shared native Godot UI tokens. See DESIGN.md and UX-CONTRACT.md.
const INK := Color("20102f")
const NIGHT := Color("160c23")
const PAPER := Color("fff1d0")
const MUTED := Color("d1becb")
const TEAL := Color("4acfe0")
const CORAL := Color("ff765e")
const GOLD := Color("ff6a00")
const EDGE := Color("62536e")
const LIME := Color("d7f400")
const FRAMES = preload("res://assets/ui/jsr/ui-frames.png")
const LOGO = preload("res://assets/ui/jsr/afterhours-logo.png")
const ICONS = preload("res://assets/ui/jsr/action-icons.png")
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
static var atlas_cache: Dictionary={}
static func atlas(id: String) -> AtlasTexture:
    if atlas_cache.has(id):return atlas_cache[id]
    var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/jsr/atlas-regions.json"))
    for item in data.frames.entries:
        if item.id!=id:continue
        var r: Array=item.region_xywh
        var b: Array=item.visible_bbox_in_region
        var result:=AtlasTexture.new()
        result.atlas=FRAMES
        result.region=Rect2(r[0]+b[0],r[1]+b[1],b[2]-b[0],b[3]-b[1])
        atlas_cache[id]=result
        return result
    return null
static func sticker(id: String) -> StyleBoxTexture:
    var style:=StyleBoxTexture.new()
    style.texture=atlas(id)
    style.texture_margin_left=60
    style.texture_margin_right=60
    style.texture_margin_top=8
    style.texture_margin_bottom=8
    style.content_margin_left=24
    style.content_margin_right=24
    style.content_margin_top=6
    style.content_margin_bottom=6
    return style
static func icon(index: int) -> AtlasTexture:
    var texture:=AtlasTexture.new()
    texture.atlas=ICONS
    var x0:=floori(float(index%4)*ICONS.get_width()/4)
    var y0:=floori(float(floori(index/4.0))*ICONS.get_height()/4)
    var x1:=floori(float(index%4+1)*ICONS.get_width()/4)
    var y1:=floori(float(floori(index/4.0)+1)*ICONS.get_height()/4)
    texture.region=Rect2(x0,y0,x1-x0,y1-y0)
    return texture
static func build() -> Theme:
    var theme:=Theme.new()
    theme.default_font=BODY
    theme.default_font_size=17
    theme.set_color("font_color","Label",PAPER)
    for type_name in ["Button","OptionButton","CheckButton","PopupMenu"]:
        theme.set_color("font_color",type_name,PAPER)
        theme.set_color("font_outline_color",type_name,INK)
        theme.set_constant("outline_size",type_name,4)
        theme.set_color("font_hover_color",type_name,PAPER)
        theme.set_color("font_focus_color",type_name,PAPER)
        theme.set_color("font_disabled_color",type_name,INK)
        theme.set_stylebox("normal",type_name,sticker("button_normal"))
        theme.set_stylebox("hover",type_name,sticker("button_hover"))
        theme.set_stylebox("pressed",type_name,sticker("button_selected"))
        theme.set_stylebox("disabled",type_name,sticker("button_disabled"))
        theme.set_stylebox("focus",type_name,plate(Color.TRANSPARENT,LIME,3))
    for native_type in ["OptionButton","CheckButton"]:
        theme.set_stylebox("normal",native_type,plate(INK,EDGE,1))
        theme.set_stylebox("hover",native_type,plate(INK.lightened(.14),LIME,2))
        theme.set_stylebox("pressed",native_type,plate(INK.lightened(.08),LIME,2))
        theme.set_color("font_color",native_type,PAPER)
        theme.set_color("font_hover_color",native_type,PAPER)
        theme.set_color("font_pressed_color",native_type,PAPER)
        theme.set_color("font_focus_color",native_type,PAPER)
        theme.set_constant("outline_size",native_type,0)
    theme.set_color("font_pressed_color","Button",PAPER)
    theme.set_stylebox("panel","PopupMenu",plate(NIGHT,TEAL,1))
    theme.set_color("font_color","PopupMenu",PAPER)
    theme.set_color("font_hover_color","PopupMenu",INK)
    theme.set_stylebox("hover","PopupMenu",plate(TEAL))
    # Scrollbars need their own margins: menu-panel padding makes a 36 px thumb.
    for state in ["scroll","grabber","grabber_highlight","grabber_pressed"]:
        var tint: Color={"scroll":NIGHT,"grabber":MUTED.darkened(.25),"grabber_highlight":TEAL,"grabber_pressed":GOLD}[state]
        var scrollbar:=StyleBoxFlat.new()
        scrollbar.bg_color=tint
        scrollbar.content_margin_left=8
        scrollbar.content_margin_right=8
        scrollbar.content_margin_top=0 if state=="scroll" else 12
        scrollbar.content_margin_bottom=0 if state=="scroll" else 12
        theme.set_stylebox(state,"VScrollBar",scrollbar)
    theme.set_stylebox("slider","HSlider",plate(EDGE))
    theme.set_stylebox("grabber_area","HSlider",plate(TEAL))
    theme.set_stylebox("grabber_area_highlight","HSlider",plate(GOLD))
    return theme
