extends Translation
## Presentation-only catalog; save IDs, events and simulation remain in English.
var entries:Dictionary={}
var folded:Dictionary={}
var han:=RegEx.new()
var latin:=RegEx.new()
var patterns:Array=[]
var fragments:Array=[]
var cache:Dictionary={}
func load_catalog() -> void:
    entries=JSON.parse_string(FileAccess.get_file_as_string("res://assets/localization/zh_TW.json"))
    han.compile("[一-鿿]")
    latin.compile("[A-Za-z]")
    for key:String in entries:folded[key.to_lower()]=entries[key]
    var token:=RegEx.new();token.compile("%[-+0 #]*[0-9]*(?:\\.[0-9]+)?[sdfi]|\\{hero\\}")
    var keys:=entries.keys();keys.sort_custom(func(a:String,b:String)->bool:return a.length()>b.length())
    for key:String in keys:
        var matches:=token.search_all(key)
        if not matches.is_empty():
            var expression:="(?is)^";var at:=0
            for found in matches:
                expression+=escape_regex(key.substr(at,found.get_start()-at))
                expression+="(.+?)" if found.get_string().ends_with("s") or found.get_string()=="{hero}" else "(-?[0-9]+(?:\\.[0-9]+)?)"
                at=found.get_end()
            expression+=escape_regex(key.substr(at))+"$"
            var regex:=RegEx.new()
            if regex.compile(expression)!=OK:continue
            # Sequential replacement supports repeated %d specifiers.
            var rendered:String=entries[key]
            var offset:=0;var chunks:="";var index:=0
            for found in token.search_all(rendered):
                chunks+=rendered.substr(offset,found.get_start()-offset)+"{"+str(index)+"}"
                offset=found.get_end();index+=1
            chunks+=rendered.substr(offset)
            patterns.append({"regex":regex,"text":chunks.replace("%%","%")})
        elif not key.is_empty():
            var regex:=RegEx.new()
            var left:="(?<![A-Za-z_])" if key[0].is_valid_identifier() else ""
            var right:="(?![A-Za-z_])" if key[-1].is_valid_identifier() else ""
            if regex.compile(left+escape_regex(key)+right)==OK:fragments.append({"regex":regex,"text":str(entries[key])})
func escape_regex(value:String) -> String:
    var result:=""
    for char in value.replace("%%","%"):
        result+=("\\" if char in "\\.^$|?*+()[]{}" else "")+char
    return result
func translated(value:String) -> String:
    if value.is_empty() or han.search(value)!=null or latin.search(value)==null:return value
    if entries.has(value):return str(entries[value])
    if folded.has(value.to_lower()):return str(folded[value.to_lower()])
    if cache.has(value):return cache[value]
    var result:=value
    for pattern in patterns:
        var found:RegExMatch=pattern.regex.search(value)
        if found!=null:
            var values:Array=[]
            for i in range(1,found.get_group_count()+1):values.append(translated(found.get_string(i)))
            result=pattern.text.format(values);break
    if result==value:
        if value.contains("\n"):
            var lines:=value.split("\n")
            for i in lines.size():lines[i]=translated(lines[i])
            result="\n".join(lines)
        else:
            for fragment in fragments:result=fragment.regex.sub(result,fragment.text,true)
    if cache.size()>2048:cache.clear()
    cache[value]=result
    return result
func _get_message(message:StringName,_context:StringName) -> StringName:
    return StringName(translated(str(message)))
