extends Node
const Catalog=preload("res://scripts/combat/ui/translation_catalog.gd")
var catalog:Translation
var language:="en"
func _ready() -> void:
    catalog=Catalog.new();catalog.locale="zh_TW";catalog.load_catalog()
    TranslationServer.add_translation(catalog)
    set_language("en")
    get_tree().node_added.connect(_node_added)
func set_language(value:String) -> void:
    language="zh" if value in ["zh","zh_TW","zh_Hant"] else "en"
    TranslationServer.set_locale("zh_TW" if language=="zh" else "en")
func text(value:String) -> String:
    return str(TranslationServer.translate(value)) if language=="zh" else value
func _node_added(node:Node) -> void:
    if node is Label3D:
        node.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
        if node.font==null:node.font=preload("res://scripts/combat/ui/ui_theme.gd").BODY
func _exit_tree() -> void:
    if catalog!=null:TranslationServer.remove_translation(catalog)
