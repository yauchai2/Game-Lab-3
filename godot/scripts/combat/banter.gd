extends RefCounted
## G3/G4/G7: original pre-fight and result lines plus a local rival memory. Presentation only.
## Lines are [zh, en]. No rule, damage or music effect; Demo/training/fixtures never touch the store.
const NAMES:=["ZIP","RIVET","HUSH","LOOP"]
const START:={
    0:[["地址會變，路我記得。","ADDRESSES CHANGE. I KNOW THE ROUTE."],["先簽收，再說話。","SIGN FOR IT FIRST."],["別擋路，我趕末班。","MOVE. I HAVE A LAST TRAIN."],["退路，我都數過了。","I COUNTED EVERY EXIT."]],
    1:[["今天收工前打完。","I'LL FINISH THIS BEFORE CLOSING."],["這一拳，我留了很久。","I'VE SAVED THIS ONE FOR A WHILE."],["停工通知，現在生效。","WORK STOPPED. STARTING NOW."],["慢慢來，反正你跑不遠。","TAKE YOUR TIME. YOU WON'T GO FAR."]],
    2:[["……（壓低帽沿）","...(TILTS CAP DOWN)"],["靜一點，聽你出手。","QUIET. I'LL HEAR YOU MOVE."],["你先。我等。","YOU FIRST. I'LL WAIT."],["多餘的聲音，都剪掉。","CUT EVERY EXTRA SOUND."]],
    3:[["站好，我佈點了。","STAND THERE. THE POINTS ARE SET."],["下一步，我替你選。","I'LL PICK YOUR NEXT STEP."],["接線完成，開始測試。","PATCHED IN. TEST STARTING."],["別亂動，線會斷。","DON'T MOVE. THE LINE WILL BREAK."]],
}
const WIN:={
    0:[["送到了。","DELIVERED."],["路線，我贏了。","ROUTE'S MINE."]],
    1:[["收工。","CLOSING TIME."],["這一鉚，釘牢了。","THAT RIVET HOLDS."]],
    2:[["……聽到了嗎？沒聲音。","HEAR THAT? NOTHING."],["留白，剛剛好。","DEAD AIR. PERFECT."]],
    3:[["測試通過。","TEST PASSED."],["線，接好了。","LINE'S LIVE."]],
}
const MIRROR:=[["你不是第一個送件的人。","YOU'RE NOT THE FIRST TO DELIVER."],["同一條路，誰先到站？","SAME ROUTE. WHO ARRIVES FIRST?"],["看著自己打，感覺怪怪的。","FIGHTING MYSELF FEELS WRONG."]]
const STREAK_LINES:=[["第五次了。你到底在背什麼？","FIFTH TIME. WHAT ARE YOU MEMORIZING?"],["我記得你的節奏了，這次不一樣。","I KNOW YOUR RHYTHM. NOT THIS TIME."]]
const RADIO_WIN:=[["電台：這一場，街區聽見了。","RADIO: THE BLOCK HEARD THAT ONE."],["電台：末班車延後三分鐘，慶祝一下。","RADIO: LAST TRAIN HELD THREE MINUTES. ENJOY IT."],["電台：路燈亮了一格。","RADIO: A STREETLIGHT JUST CAME ON."]]
const RADIO_LOSE:=[["電台：沒事，下一班很快到。","RADIO: NEXT TRAIN IS COMING SOON."],["電台：街區記住了這一課。","RADIO: THE BLOCK REMEMBERS THIS LESSON."],["電台：深呼吸，再按一次 Enter。","RADIO: BREATHE. HIT ENTER AGAIN."]]
## G8: a per-match style title from the player's own events.
const STYLES:={
    "offense":[["連段跑者","COMBO RUNNER"],["街頭推進器","STREET PUSHER"]],
    "defense":[["冷靜接線員","COOL OPERATOR"],["反擊收件人","COUNTER RECEIVER"]],
    "air":[["低空航道客","LOWWAY FLYER"],["落地前不收工","NO CLOSING BEFORE LANDING"]],
    "quiet":[["暖身班次","WARM-UP SHIFT"]],
}
## G5: short maker notes unlocked after collecting every street tag. Original; reflect repo decisions.
const NOTES:=[["製作筆記：音樂只淡入淡出，不停下來。","DEV NOTE: THE MUSIC ONLY CROSSFADES. IT NEVER STOPS."],["製作筆記：標記沒有字，是在等你自己的招牌。","DEV NOTE: THE TAGS HAVE NO TEXT. THEY'RE WAITING FOR YOUR OWN SIGNS."],["製作筆記：演出可以誇張，判定永遠只有一份。","DEV NOTE: THE SHOW CAN BE LOUD. THE RULES HAVE ONE OWNER."],["製作筆記：標準對戰數值固定，成長不影響公平。","DEV NOTE: STANDARD FIGHTS KEEP FIXED NUMBERS."],["製作筆記：F2 隨時能把演出收小。","DEV NOTE: F2 TURNS THE SPECTACLE DOWN ANY TIME."],["製作筆記：這條街原本只是白盒。","DEV NOTE: THIS STREET STARTED AS A WHITEBOX."]]
const STREAK_AT:=5
static func start_line(player:int,rival:int,streak:int,salt:int,english:bool) -> String:
    var side:=1 if english else 0
    var pool:Array
    if player==rival:pool=MIRROR
    elif streak>=STREAK_AT:pool=STREAK_LINES
    else:pool=START[clampi(rival,0,3)]
    var line:Array=pool[absi(salt)%pool.size()]
    var who:String=NAMES[clampi(player if player==rival else rival,0,3)]
    return "%s: %s"%[who,line[side]]
static func win_line(winner_character:int,salt:int,english:bool) -> String:
    var pool:Array=WIN[clampi(winner_character,0,3)]
    var line:Array=pool[absi(salt)%pool.size()]
    return "%s: %s"%[NAMES[clampi(winner_character,0,3)],line[1 if english else 0]]

static func style_title(stats:Dictionary,salt:int,english:bool) -> String:
    var offense:int=int(stats.get("hits",0));var defense:int=int(stats.get("defense",0));var air:int=int(stats.get("air",0))
    var key:="quiet"
    if offense+defense+air>=3:
        key="defense"
        var best:=defense
        if air>best:key="air";best=air
        if offense>best:key="offense"
    var pool:Array=STYLES[key]
    return pool[absi(salt)%pool.size()][1 if english else 0]
static func dev_note(salt:int,english:bool) -> String:
    return NOTES[absi(salt)%NOTES.size()][1 if english else 0]
static func radio_line(player_won:bool,salt:int,english:bool) -> String:
    var pool:Array=RADIO_WIN if player_won else RADIO_LOSE
    return pool[absi(salt)%pool.size()][1 if english else 0]

## Local-only win-streak memory against the same rival character (G4). Schema versioned, clamped, optional.
class Store extends RefCounted:
    const VERSION:=1
    var path:=""
    var rival:=-1
    var streak:=0
    func _init(p:="") -> void:
        path=p;load_data()
    func load_data() -> void:
        rival=-1;streak=0
        if path.is_empty():return
        var f:=ConfigFile.new()
        if f.load(path)!=OK or int(f.get_value("memory","version",0))!=VERSION:return
        var r:Variant=f.get_value("memory","rival",-1);var s:Variant=f.get_value("memory","streak",0)
        if typeof(r)==TYPE_INT and typeof(s)==TYPE_INT:rival=clampi(r,-1,3);streak=clampi(s,0,999)
    func streak_against(character:int) -> int:return streak if rival==character else 0
    func record(rival_character:int,player_won:bool) -> void:
        rival_character=clampi(rival_character,0,3)
        if player_won:
            streak=streak+1 if rival==rival_character else 1
            rival=rival_character
        else:
            rival=rival_character;streak=0
        save()
    func save() -> void:
        if path.is_empty():return
        var f:=ConfigFile.new()
        f.set_value("memory","version",VERSION);f.set_value("memory","rival",rival);f.set_value("memory","streak",streak)
        DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
        f.save(path)
