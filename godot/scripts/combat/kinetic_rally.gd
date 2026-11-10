extends RefCounted
## Bounded practice experiment. One 60 Hz clock; no scene/input/audio dependencies.
const HOLDS := [12,16,22,30]
const WINDOWS := [12,10,9,8]
const DAMAGE := [12,16,21,27]
const WINDUP := 10
const MAX_TICKS := 300
var phase := "idle"
var owner := -1
var tier := 0
var age := 0
var elapsed := 0
var serial := 0
var chosen := false
var guard_window := [0,0]
var guard_lock := [0,0]
var guard_buffer := [false,false]
var reason := ""

func active() -> bool:
    return phase!="idle"

func reset() -> void:
    phase="idle"
    owner=-1
    tier=0
    age=0
    elapsed=0
    serial=0
    chosen=false
    reason=""
    guard_window=[0,0]
    guard_lock=[0,0]
    guard_buffer=[false,false]

func begin(side: int) -> void:
    elapsed=0
    tier=1
    _transfer(side)

func _transfer(side: int) -> void:
    owner=side
    phase="compress"
    age=0
    serial+=1
    chosen=false
    guard_window=[0,0]
    guard_lock=[0,0]
    guard_buffer=[false,false]
    reason=""

func return_parry(side: int) -> bool:
    if tier>=4:
        finish("limit")
        return false
    tier+=1
    _transfer(side)
    return true

func finish(why: String) -> void:
    phase="idle"
    reason=why
    guard_window=[0,0]
    guard_lock=[0,0]
    guard_buffer=[false,false]

func tick(commands: Array) -> String:
    if not active():return ""
    elapsed+=1
    if elapsed>=MAX_TICKS:
        finish("timeout")
        return "end"
    age+=1
    if phase=="compress":
        if HOLDS[tier-1]-age<=8 and commands[1-owner].get("guard_pressed",false):guard_buffer[1-owner]=true
        if commands[owner].get("attack","")=="light":chosen=true
        if age>=HOLDS[tier-1]:
            if not chosen:
                finish("no_input")
                return "end"
            phase="windup"
            age=0
            return "windup"
        return ""
    var defender:=1-owner
    for i in 2:
        guard_window[i]=maxi(0,guard_window[i]-1)
        guard_lock[i]=maxi(0,guard_lock[i]-1)
    var buffered: bool=guard_buffer[defender] and age>=maxi(1,WINDUP-WINDOWS[tier-1]+1)
    if (commands[defender].get("guard_pressed",false) or buffered) and guard_lock[defender]==0:
        guard_buffer[defender]=false
        guard_window[defender]=WINDOWS[tier-1]
        guard_lock[defender]=WINDOWS[tier-1]+10
    if phase=="windup" and age>=WINDUP:
        phase="active"
        age=0
        return "release"
    if phase=="active" and age>=5:
        finish("whiff")
        return "end"
    return ""
