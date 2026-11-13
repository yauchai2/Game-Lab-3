extends RefCounted
## Available during preload and isolated strict compilation, before autoload nodes exist.
static func text(value:String) -> String:
    return str(TranslationServer.translate(value)) if TranslationServer.get_locale().begins_with("zh") else value
