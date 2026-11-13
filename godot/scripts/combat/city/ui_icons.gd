extends RefCounted
## Chunky 12x12 pixel icons for the hub pages. One owner, no art files: every glyph is a string bitmap.
## k=ink outline, w=paper, g=grey, a=primary tint, b=secondary tint. '.' is transparent.
const T=preload("res://scripts/combat/ui/ui_theme.gd")
const PX:=4 # logical pixels per icon pixel; the 960x540 framebuffer shows 3 real pixels each.
const GLYPHS:={
"double_jump":["....kkkk....","...kaaaak...","..kaakkaak..",".kaakkkkaak.","kaak.kk.kaak","kkk..kk..kkk","....kkkk....","...kbbbbk...","..kbbkkbbk..",".kbbkkkkbbk.","kbbk.kk.kbbk","kkk..kk..kkk"],
"launcher":["....kkkk....","...kaaaak...","..kaaaaaak..",".kaaaaaaaak.","kkkkaaaakkkk","...kaaaak...","...kaaaak...","...kaaaak...",".kkkaaaakkk.",".kbbbbbbbbk.",".kbbbbbbbbk.",".kkkkkkkkkk."],
"chase":["............",".kk..kk.....",".kak.kak....",".kaak.kaak..",".kaaak.kaaak",".kaaaak.kaaa",".kaaaak.kaaa",".kaaak.kaaak",".kaak.kaak..",".kak.kak....",".kk..kk.....","............"],
"finisher":["....kkkk....","k...kaak...k","kk..kaak..kk",".kk.kaak.kk.","..kkkaakkk..","kkaaaaaaaakk","kkaaaaaaaakk","..kkkaakkk..",".kk.kaak.kk.","kk..kaak..kk","k...kaak...k","....kkkk...."],
"overdrive":["......kkkk..",".....kaaak..","....kaaak...","...kaaak....","..kaaaaaakk.",".kaaaaaaak..",".kkkkaaak...","....kaak....","...kaak.....","...kak......","..kak.......","..kk........"],
"fist":["..kkkkkkk...",".kaaaaaaak..","kaakaakaakk.","kaakaakaakak","kaakaakaakak","kaaaaaaaaaak","kaaaaaaaaaak",".kaaaaaaaak.","..kaaaaaak..","..kbbbbbbk..","..kbbbbbbk..","..kkkkkkkk.."],
"kick":["...kkk......","...kak......","...kak......","...kak......","..kaaak.....","..kaaaakkkk.","..kaaaaaaaak",".kaaaaaaaaak",".kbbbbbbbbbk",".kbbbbbbbbbk",".kkkkkkkkkkk","............"],
"ring":["...kkkkkk...","..kaaaaaak..",".kaakkkkaak.","kaak....kaak","kak......kak","kak..kk..kak","kak..kk..kak","kak......kak","kaak....kaak",".kaakkkkaak.","..kaaaaaak..","...kkkkkk..."],
"coin":["...kkkkkk...","..kaaaaaak..",".kaaaakaaak.","kaaaakkaaaak","kaaakaaaaaak","kaaaakkkaaak","kaaaaaakaaak","kaaakaaakaak","kaaaakkkaaak",".kaaaakaaak.","..kaaaaaak..","...kkkkkk..."],
"gear":[".....kk.....",".kk.kaak.kk.",".kakkaakkak.","..kaaaaaak..",".kaakkkkaak.","kaaak..kaaak","kaaak..kaaak",".kaakkkkaak.","..kaaaaaak..",".kakkaakkak.",".kk.kaak.kk.",".....kk....."],
"lock":["...kkkkkk...","..kggkkggk..","..kg....gk..","..kg....gk..",".kkkkkkkkkk.",".kggggggggk.",".kggggkkggk.",".kgggkkkkgk.",".kggggkkggk.",".kggggkkggk.",".kggggggggk.",".kkkkkkkkkk."],
"check":["............","..........kk",".........kak","........kaak",".......kaak.","kk....kaak..","kak..kaak...","kaakkaak....",".kaaaak.....","..kaak......","...kk.......","............"],
"play":["............","..kk........","..kakk......","..kaakkk....","..kaaaakkk..","..kaaaaaakk.","..kaaaaaakk.","..kaaaakkk..","..kaakkk....","..kakk......","..kk........","............"],
"heart":["............",".kkk....kkk.","kaaakkkkaaak","kaaaaaaaaaak","kaaaaaaaaaak","kaaaaaaaaaak",".kaaaaaaaak.","..kaaaaaak..","...kaaaak...","....kaak....",".....kk.....","............"],
"shield":[".kkkkkkkkkk.",".kaaaakaaak.",".kaaaakaaak.",".kaaaakaaak.",".kaaaakaaak.",".kkkkkkkkkk.",".kaaaaaaaak.","..kaaaaaak..","..kaaaaaak..","...kaaaak...","....kaak....",".....kk....."],
"box":["............","..kkkkkkkk..",".kaaaaaaaak.","kkkkkkkkkkkk","kaaaakkaaaak","kaaaakkaaaak","kaaaakkaaaak","kaaaakkaaaak","kaaaakkaaaak","kaaaakkaaaak","kkkkkkkkkkkk","............"],
"skull":["...kkkkkk...","..kwwwwwwk..",".kwwwwwwwwk.","kwwkkwwkkwwk","kwwkkwwkkwwk","kwwwwkkwwwwk",".kwwwkkwwwk.","..kwwwwwwk..","..kwkwkwkwk.","..kkkkkkkk..","............","............"],
"bed":["............","............","kk..........","kak.kkkkkkk.","kakkkbbbbbbk","kaaaaaaaaaak","kaaaaaaaaaak","kkkkkkkkkkkk","kk........kk","kk........kk","............","............"],
"flag":["..kk........","..kakkkkk...","..kaaaaaakk.","..kaaaaaaak.","..kaaaaaakk.","..kakkkkk...","..kk........","..kk........","..kk........","..kk........",".kkkk.......","............"],
"pin":["....kkkk....","...kaaaak...","..kaakkaak..","..kaakkaak..","..kaaaaaak..","...kaaaak...","...kaaaak...","....kaak....","....kaak....",".....kk.....","............","............"],
"radio":["........kk..",".......kak..","......kak...","kkkkkkkkkkk.","kggggggggggk","kgkkkggkkgak","kgkkkggkkgak","kggggggggggk","kgkkkkkkkgbk","kggggggggggk","kkkkkkkkkkk.","............"],
"circuit":["kkk.........","kak.kkkkkkk.","kakkkaaaaak.","kaaaakkkkak.","kkk.....kak.","....kkk.kak.",".kkkkak.kaak","kkkkaak..kak","kaaaakk..kak","kkkk.kkkkkak","......kkkkkk","............"],
"core":["...kkkkkk...","..kaaaaaak..",".kaaaaaaaak.",".kaakkkkaak.",".kaakwwkaak.",".kaakwwkaak.",".kaakkkkaak.",".kaaaaaaaak.",".kbbbbbbbbk.",".kbbbbbbbbk.","..kkkkkkkk..","............"],
"bag":["...kkkkkk...","..kk....kk..","..kk....kk..",".kkkkkkkkkk.","kaaaaaaaaaak","kaaaakkaaaak","kaaaaaaaaaak","kaaaaaaaaaak","kaaaaaaaaaak","kaaaaaaaaaak","kkkkkkkkkkkk","............"],
"wrist":["............","..kkkkkkkk..",".kaaaaaaaak.","kaakkkkkkaak","kaak....kaak","kaak....kaak","kaak....kaak","kaakkkkkkaak",".kaaaaaaaak.","..kkkkkkkk..","............","............"],
"sole":["............","............","kkkk........","kaak........","kaak....kkk.","kaaakkkkkak.","kaaaaaaaaaak","kaaaaaaaaaak","kbbbbbbbbbbk","kkkkkkkkkkkk","............","............"],
"belt":["............","kkkkkkkkkkkk","kaaaaaaaaaak","kaaakkkkaaak","kaaakbbkaaak","kaaakbbkaaak","kaaakkkkaaak","kaaaaaaaaaak","kkkkkkkkkkkk","............","............","............"],
"keeper":["...kkkkkk...","..kaaaaaak..",".kaaaaaaaak.",".kaakkkkaak.",".kaakwwkaak.",".kaakwwkaak.","..kakkkkak..","..kaaaaaak..",".kaaaaaaaak.","kaaaaaaaaaak","kkkkkkkkkkkk","............"],
"dealer":["..kkkkkkkk..",".kaaaaaaaak.","kaaaaaaaaaak","kkkkkkkkkkkk","..kwwwwwwk..","..kkkkkkkk..","..kwwwwwwk..","..kwwkkwwk..","...kwwwwk...",".kaaakkaaak.","kaaaaaaaaaak","kkkkkkkkkkkk"],
"mechanic":["..kkkkkkkk..",".kaaaaaaaak.",".kkkkkkkkkk.","kbbkkbbkkbbk","kbbkkbbkkbbk",".kkkkkkkkkk.","..kwwwwwwk..","..kwwwwwwk..","...kwwwwk...",".kaaakkaaak.","kaaaaaaaaaak","kkkkkkkkkkkk"],
"hero":["...kkkkkk...","..kaaaaaak..",".kaaaaaaaak.",".kaakkkkaak.",".kakwwwwkak.",".kakwkkwkak.",".kaakwwkaak.","..kaaaaaak..","...kakkak...","..kaaaaaak..",".kaaaaaaaak.","kkkkkkkkkkkk"],
"swords":["kk........kk","kak......kak",".kak....kak.","..kak..kak..","...kakkak...","....kaak....","...kakkak...","..kak..kak..",".kbk....kbk.","kbk......kbk","kk........kk","............"],
"bolt":["......kkkk..",".....kaaak..","....kaaak...","...kaaak....","..kaaaaaakk.",".kaaaaaaak..",".kkkkaaak...","....kaak....","...kaak.....","...kak......","..kak.......","..kk........"],
"star":[".....kk.....",".....kak....","....kaak....","kkkkkaakkkkk","kaaaaaaaaaak",".kaaaaaaaak.","..kaaaaaak..","..kaaaaaak..",".kaaakkaaak.",".kaakk.kaak.","kaak....kaak","kk........kk"],
"info":["...kkkkkk...","..kaaaaaak..",".kaaakkaaak.",".kaaakkaaak.",".kaaaaaaaak.",".kaaakkaaak.",".kaaakkaaak.",".kaaakkaaak.",".kaaakkaaak.","..kaaaaaak..","...kkkkkk...","............"],
"close":["............",".kk......kk.","kaak....kaak",".kaak..kaak.","..kaakkaak..","...kaaaak...","...kaaaak...","..kaakkaak..",".kaak..kaak.","kaak....kaak",".kk......kk.","............"],
"arrow":["............",".....kk.....",".....kak....",".....kaak...","kkkkkkaaak..","kaaaaaaaaak.","kaaaaaaaaak.","kkkkkkaaak..",".....kaak...",".....kak....",".....kk.....","............"],
"dice":["kkkkkkkkkkkk","kaaaaaaaaaak","kakkaaaakkak","kakkaaaakkak","kaaaaaaaaaak","kaaaakkaaaak","kaaaakkaaaak","kaaaaaaaaaak","kakkaaaakkak","kakkaaaakkak","kaaaaaaaaaak","kkkkkkkkkkkk"],
"book":["............","kkkkkkkkkkk.","kaaaaakbbbk.","kakkkakbbbk.","kaaaaakbbbk.","kakkkakbbbk.","kaaaaakbbbk.","kakkkakbbbk.","kaaaaakbbbk.","kkkkkkkkkkk.","............","............"]}
static var cache:Dictionary={}
static func texture(id:String,tint:Color=T.PAPER,second:Color=T.CORAL) -> ImageTexture:
    var key:=id+tint.to_html()+second.to_html()
    if cache.has(key):return cache[key]
    var rows:Array=GLYPHS.get(id,GLYPHS.info)
    var image:=Image.create(12,12,false,Image.FORMAT_RGBA8)
    var palette:={"k":T.INK,"w":T.PAPER,"g":T.EDGE,"a":tint,"b":second}
    for y in 12:
        var row:String=rows[y]
        for x in 12:
            var c:=row.substr(x,1)
            if palette.has(c):image.set_pixel(x,y,palette[c])
    var result:=ImageTexture.create_from_image(image)
    cache[key]=result
    return result
static func rect(id:String,tint:Color=T.PAPER,second:Color=T.CORAL,scale:int=1) -> TextureRect:
    var node:=TextureRect.new();node.texture=texture(id,tint,second)
    node.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;node.stretch_mode=TextureRect.STRETCH_SCALE
    node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;node.custom_minimum_size=Vector2(12*PX*scale,12*PX*scale)
    node.mouse_filter=Control.MOUSE_FILTER_IGNORE
    return node
