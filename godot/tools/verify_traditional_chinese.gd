extends SceneTree
const Catalog=preload("res://scripts/combat/ui/translation_catalog.gd")
const Prefs=preload("res://scripts/combat/fight_preferences.gd")
const OUT="res://../docs/evidence/chinese-pixel-preset/"
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("ZH ",label," ",ok)
    if not ok:push_error(label)
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    var locale=root.get_node("GameLocale")
    locale.set_language("en")
    check("English interface remains unchanged",locale.text("SETTINGS")=="SETTINGS")
    locale.set_language("zh")
    check("Traditional Chinese menu copy",locale.text("SETTINGS")=="設定" and locale.text("FIGHTERS")=="角色")
    check("Formatted encounter retains its numbers",locale.text("ENCOUNTER 3 / 18")=="遭遇戰3／18")
    check("Formatted contract retains both counters",locale.text("CONTRACT WAVE 2 OF 3 CLEAR")=="合約第2波／共3波完成")
    check("Repeated printf placeholders preserve order",locale.text("CREDITS 250   PARTS 12   CHAIN x4")=="金幣250　零件12　連戰×4")
    check("Percent signs survive formatting",locale.text("TOTAL HP +30% / DAMAGE +15% (CAPPED)")=="總生命＋30%／傷害＋15%（已套用上限）")
    check("Generated item quality and slot names translate",locale.text("RARE WRISTS")=="稀有 護腕")
    check("Underlying item IDs and key codes stay stable",locale.text("relay_brace")=="relay_brace" and locale.text("W+L")=="W+L")
    check("Mixed story speakers and full lines translate",locale.text("ZIP: Delivered. Signed for. For once the right door.").contains("今次終於送啱門口"))
    check("Named story placeholders resolve after inserting the hero",locale.text("I'll hold the door. ZIP out.").begins_with("我去守住門口。"))
    var label:=Label.new();label.text="SETTINGS";root.add_child(label)
    check("Native controls use the shared TranslationServer",label.tr(label.text)=="設定")
    check("Already-localized names are not translated twice",locale.text("疾扣 ZIP")=="疾扣 ZIP")
    check("Uppercase native buttons use the same copy",locale.text("RESUME FIGHT")==locale.text("Resume fight"))
    var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/localization/zh_TW.json"))
    var font=load("res://assets/fonts/RadioChinese.tres");var missing:Array=[]
    for value:String in data.values():
        for char in value:
            var code:=char.unicode_at(0)
            if code>=0x3400 and code<=0x9fff and not font.has_char(code) and char not in missing:missing.append(char)
    check("Bundled Chinese font covers every catalog Han character",missing.is_empty())
    check("Chinese runtime fallback is bitmap rather than MSDF",font.base_font.resource_path.ends_with("RadioPixelChinese.fnt") and not font.base_font.multichannel_signed_distance_field)
    var source_font=load("res://assets/fonts/AfterhoursUIHK.otf")
    check("Chinese pixel font preserves full-size text advances",is_equal_approx(font.get_string_size("繁體中文",HORIZONTAL_ALIGNMENT_LEFT,-1,24).x,source_font.get_string_size("繁體中文",HORIZONTAL_ALIGNMENT_LEFT,-1,24).x))
    var lines=preload("res://scripts/combat/city/story_script.gd")
    var spoken:Array=lines.PROLOGUE.duplicate(true)
    for chapter in lines.CHAPTERS:spoken.append_array(chapter.intro);spoken.append_array(chapter.outro)
    spoken.append_array(lines.ENCOUNTERS)
    for boss in lines.BOSS_ENTRANCES.values():spoken.append_array(boss)
    for ending in lines.ENDINGS.values():spoken.append_array(ending.lines)
    spoken.append_array(lines.TRUE_SCENE)
    var untranslated:Array=[]
    for line in spoken:
        if not data.has(str(line[1])):untranslated.append(line[1])
    for closing in lines.HERO_CLOSING.values():
        if not data.has(str(closing).split(": ",true,1)[1]):untranslated.append(closing)
    check("All authored campaign dialogue and ending lines have full translations",untranslated.is_empty())
    var world_label:=Label3D.new();world_label.text="夜班";root.add_child(world_label)
    check("World text keeps the shared pixel face and nearest sampling",world_label.font.resource_path=="res://assets/fonts/RadioBody.tres" and world_label.texture_filter==BaseMaterial3D.TEXTURE_FILTER_NEAREST)
    world_label.queue_free()
    var p:=Prefs.new();var path:="user://traditional-chinese/preferences.cfg"
    var options:Dictionary=p.DEFAULTS.duplicate();options.language="zh"
    check("Language choice saves and reloads",p.write_options(path,options)==OK and p.read_options(path).language=="zh")
    options.language="en";p.write_options(path,options)
    check("English can be restored and saved",p.read_options(path).language=="en")
    locale.set_language("en");check("Existing native controls restore English",label.tr(label.text)=="SETTINGS")
    label.queue_free();await process_frame
    var failed:int=checks.filter(func(c):return not c.passed).size()
    FileAccess.open(OUT+"rules.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"catalog_entries":data.size(),"missing_glyphs":missing},"  "))
    quit(0 if failed==0 else 1)
