extends RefCounted
## Shared native Godot UI tokens. See DESIGN.md and UX-CONTRACT.md.
## Logical 1280x720 UI renders at 1:1 in the shared 1280x720 framebuffer.
const CAPTION_SIZE:=24
const BODY_SIZE:=28
const ACTION_SIZE:=32
const INK := Color("000000")
const NIGHT := Color("090b0e")
const PAPER := Color("f7f9fa")
const MUTED := Color("bcc5cc")
const TEAL := Color("00d6e7")
const CORAL := Color("ff008c")
const GOLD := Color("ff008c")
const EDGE := Color("505660")
const MAGENTA := Color("ff008c")
const LIME := Color("bdff00")
const LOGO = preload("res://assets/ui/ink/logo.tres")
## Crisp 20 px binary glyphs use hard pixel steps and preserve letter gaps.
const BODY = preload("res://assets/fonts/RadioBody.tres")
const DISPLAY = preload("res://assets/fonts/RadioDisplay.tres")
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
# Legacy asset-inspection helpers are lazy; runtime pages use ink assets/native parts.
static var atlas_cache: Dictionary={}
static func atlas(id: String) -> AtlasTexture:
    if atlas_cache.has(id):return atlas_cache[id]
    var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/jsr/atlas-regions.json"))
    for item in data.frames.entries:
        if item.id!=id:continue
        var r: Array=item.region_xywh
        var b: Array=item.visible_bbox_in_region
        var result:=AtlasTexture.new()
        result.atlas=load("res://assets/ui/jsr/ui-frames.png")
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
    var icons:Texture2D=load("res://assets/ui/jsr/action-icons.png")
    texture.atlas=icons
    var x0:=floori(float(index%4)*icons.get_width()/4)
    var y0:=floori(float(floori(index/4.0))*icons.get_height()/4)
    var x1:=floori(float(index%4+1)*icons.get_width()/4)
    var y1:=floori(float(floori(index/4.0)+1)*icons.get_height()/4)
    texture.region=Rect2(x0,y0,x1-x0,y1-y0)
    return texture
static func build() -> Theme:
    var theme:=Theme.new()
    theme.default_font=BODY
    theme.default_font_size=BODY_SIZE
    theme.set_color("font_color","Label",PAPER)
    for type_name in ["Button","OptionButton","CheckButton","PopupMenu"]:
        theme.set_color("font_color",type_name,PAPER)
        theme.set_color("font_outline_color",type_name,INK)
        theme.set_constant("outline_size",type_name,4)
        theme.set_color("font_hover_color",type_name,PAPER)
        theme.set_color("font_focus_color",type_name,PAPER)
        theme.set_color("font_disabled_color",type_name,INK)
        theme.set_stylebox("normal",type_name,plate(NIGHT,EDGE,1))
        theme.set_stylebox("hover",type_name,plate(INK,TEAL,2))
        theme.set_stylebox("pressed",type_name,plate(TEAL,INK,2))
        theme.set_stylebox("disabled",type_name,plate(EDGE,INK,1))
        theme.set_stylebox("focus",type_name,plate(Color.TRANSPARENT,TEAL,3))
    # Native secondary actions use opaque pixel plates; nine-sliced skew stickers
    # collapse at compact sizes and hide the recovery labels.
    for state in ["normal","hover","pressed","disabled"]:
        theme.set_stylebox(state,"Button",plate(TEAL if state in ["hover","pressed"] else PAPER,INK,2))
    for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
        theme.set_color(state,"Button",INK)
    theme.set_constant("outline_size","Button",0)
    theme.set_font("font","Button",DISPLAY)
    for native_type in ["OptionButton","CheckButton"]:
        theme.set_stylebox("normal",native_type,plate(INK,EDGE,1))
        theme.set_stylebox("hover",native_type,plate(INK.lightened(.14),TEAL,2))
        theme.set_stylebox("pressed",native_type,plate(INK.lightened(.08),TEAL,2))
        theme.set_color("font_color",native_type,PAPER)
        theme.set_color("font_hover_color",native_type,PAPER)
        theme.set_color("font_pressed_color",native_type,PAPER)
        theme.set_color("font_focus_color",native_type,PAPER)
        theme.set_constant("outline_size",native_type,0)
    theme.set_color("font_pressed_color","Button",INK)
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
    for key in ["checked","checked_mirrored"]:
        theme.set_icon(key,"CheckButton",load("res://assets/ui/ink/toggle-on.svg"))
    for key in ["unchecked","unchecked_mirrored"]:
        theme.set_icon(key,"CheckButton",load("res://assets/ui/ink/toggle-off.svg"))
    for key in ["checked_disabled","checked_disabled_mirrored"]:
        theme.set_icon(key,"CheckButton",load("res://assets/ui/ink/toggle-on-disabled.svg"))
    for key in ["unchecked_disabled","unchecked_disabled_mirrored"]:
        theme.set_icon(key,"CheckButton",load("res://assets/ui/ink/toggle-off-disabled.svg"))
    theme.set_icon("arrow","OptionButton",load("res://assets/ui/ink/select-arrow.svg"))
    theme.set_icon("grabber","HSlider",load("res://assets/ui/ink/slider-thumb.svg"))
    theme.set_icon("grabber_highlight","HSlider",load("res://assets/ui/ink/slider-thumb-focus.svg"))
    theme.set_icon("grabber_disabled","HSlider",load("res://assets/ui/ink/slider-thumb-disabled.svg"))
    theme.set_stylebox("panel","TooltipPanel",plate(NIGHT,EDGE,1))
    theme.set_color("font_color","TooltipLabel",PAPER)
    theme.set_font_size("font_size","TooltipLabel",CAPTION_SIZE)
    theme.set_stylebox("slider","HSlider",plate(EDGE))
    theme.set_stylebox("grabber_area","HSlider",plate(TEAL))
    theme.set_stylebox("grabber_area_highlight","HSlider",plate(GOLD))
    return theme
