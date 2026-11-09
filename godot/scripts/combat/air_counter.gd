extends RefCounted
## One bounded air reversal. Pure 60Hz state; no nodes or engine time scaling.
const COST := 25
const PARRY_WINDOW := 6
const HOLD := 18
const WINDUP := 10
const ACTIVE := 4
const MAX_TICKS := 90
var phase:="idle"
var owner:=-1
var age:=0
var elapsed:=0
var choice:=""
var reason:=""
var serial:=0
func active() -> bool:return phase!="idle"
func reset() -> void:
    phase="idle";owner=-1;age=0;elapsed=0;choice="";reason="";serial=0
func begin(side: int) -> void:
    phase="hold";owner=side;age=0;elapsed=0;choice="";reason="";serial+=1
func choose(value: String) -> void:
    if phase=="hold" and choice=="" and value in ["kick","escape"]:choice=value
func finish(why: String) -> void:
    phase="idle";reason=why
func tick(commands: Array, automate_owner: bool) -> String:
    if not active():return ""
    elapsed+=1
    age+=1
    if elapsed>=MAX_TICKS:finish("timeout");return "end"
    if phase=="hold":
        choose(commands[owner].get("air_choice",""))
        if automate_owner and age>=4:choose("escape" if serial%3==0 else "kick")
        if age>=HOLD:
            if choice!="kick":
                choice="escape"
                finish("escape")
                return "escape"
            phase="windup";age=0
            return "windup"
    elif phase=="windup" and age>=WINDUP:
        phase="active";age=0
        return "release"
    elif phase=="active" and age>=ACTIVE:
        finish("whiff")
        return "end"
    return ""
