extends RefCounted
## Shared pressure and a bounded, deterministic decision window. No rendering/input APIs.
const CHOICES := ["press","turn","slip"]
const WINDOW := 36
const THRESHOLD := 60.0
const MAX_PRESSURE := 90.0
var pressure := 0.0
var cooldown := 0
var quiet_ticks := 0
var serial := 0
var clash: Dictionary = {}
var last_result: Dictionary = {}
func reset() -> void:
    pressure=0.0
    cooldown=0
    quiet_ticks=0
    serial=0
    clash.clear()
    last_result.clear()
func tier() -> int:
    return clampi(1+int(pressure/30.0),1,3)
func active() -> bool:
    return not clash.is_empty()
func contact(amount: float) -> void:
    pressure=clampf(pressure+amount,0,MAX_PRESSURE)
    quiet_ticks=0
func advance_idle(separated: bool) -> void:
    cooldown=maxi(0,cooldown-1)
    quiet_ticks+=1
    if separated and quiet_ticks>30:pressure=maxf(0,pressure-.5)
    elif quiet_ticks>90:pressure=maxf(0,pressure-.35)
func begin(attacker: int, intent: String, cue := "") -> void:
    serial+=1
    clash={"attacker":attacker,"remaining":WINDOW,"choices":["",""],"intent":intent,"cue":cue if cue in CHOICES else intent}
    last_result.clear()
func choose(side: int, choice: String) -> void:
    if active() and side in [0,1] and choice in CHOICES and clash.choices[side]=="":clash.choices[side]=choice
func tick(commands: Array, automate_rival: bool, delay: int) -> bool:
    for i in 2:choose(i,commands[i].get("clash_choice",""))
    if automate_rival and WINDOW-int(clash.remaining)>=delay:choose(1,clash.intent)
    clash.remaining-=1
    if clash.remaining>0:return false
    var a: String=clash.choices[0]
    var b: String=clash.choices[1]
    var winner: int=resolve(a,b)
    last_result={"winner":winner,"choice":clash.choices[winner] if winner>=0 else "tie","choices":clash.choices.duplicate(),"attacker":clash.attacker,"rival_feint":clash.cue!=clash.intent}
    clash.clear()
    pressure=0.0
    cooldown=90
    quiet_ticks=0
    return true
static func resolve(a: String, b: String) -> int:
    if a==b:return -1
    if a not in CHOICES:return 1 if b in CHOICES else -1
    if b not in CHOICES:return 0
    return 0 if posmod(CHOICES.find(a)-CHOICES.find(b),3)==1 else 1
