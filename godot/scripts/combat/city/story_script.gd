extends RefCounted
## Authored story text for the STORY campaign. Pure data plus tiny lookups; no node, no save access.
## Speaker "@" is the hero currently on the street. "{hero}" inside text is replaced with their name.
## Existing CityStory.CHAPTERS (hub RADIO review) stay the short per-chapter briefing; this file adds the
## spoken scenes: prologue, chapter cards, one radio line per encounter, boss entrances and endings.
const HEROES=["ZIP","RIVET","HUSH","LOOP"]
const VOICE_COLORS={"ZIP":"00d6e7","RIVET":"e89441","HUSH":"f7f9fa","LOOP":"bdff00","DEALER":"ff008c","DISPATCHER":"ff5a5a","TOWER":"ff5a5a","@":"f7f9fa"}
const PROLOGUE=[
    ["HUSH","Manifest on the lid says SIGNAL KEY, times two. Owner: Tower Collections. Not speakers, LOOP.","PROLOGUE / WRONG DELIVERY"],
    ["LOOP","...I paid for speakers."],
    ["ZIP","The app said deliver to Afterhours Block. It never said deliver trouble."],
    ["RIVET","Black car outside. Three doors, all closed at once. They are not here for speakers either."],
    ["HUSH","Tonight is the last service. At dawn the old transit hub goes dark and the tower takes the channel. We keep the radio alive until then."],
    ["@","I'll hold the door. {hero} out."]]
## Chapter scenes: [intro, outro]. Chapter index = encounter room / 3.
const CHAPTERS=[
    {"title":"CHAPTER 1 / DEAD AIR",
     "intro":[["TOWER","NEIGHBOURHOOD CHANNEL SUSPENDED FOR MAINTENANCE. THANK YOU FOR YOUR PATIENCE."],["LOOP","Maintenance? They cut us the minute the case landed. The relay is in Neon Alley."],["@","Then I'm going to the alley."]],
     "outro":[["LOOP","Relay's alive! The first receiver on Old Pier Road just came back on. Hear that crackle? That's people."],["HUSH","The suits took one key and left. The other is still in the case. They will be back."],["RIVET","They went through the Toll Gate. That is their road now."]]},
    {"title":"CHAPTER 2 / TOLL GATE",
     "intro":[["ZIP","They charge the neighbours to cross their own street. Rude."],["RIVET","Shields up front. Don't trade punches with a wall. Walk around it."]],
     "outro":[["LOOP","Their dispatch channel leaked a freight order. Signed CITY SERVICE. Not Tower. City."],["HUSH","Freight route runs under the flyover, then the yard. Follow the paper."],["DEALER","Free advice from the back alley: whoever signs a paper wants it found. Or wants it hidden very badly."]]},
    {"title":"CHAPTER 3 / UNDER THE STATIC",
     "intro":[["HUSH","A jammer crew is parked under the bridge. Their blast marks the ground first. Leave the mark."],["LOOP","I will get one word through the noise if you can keep them busy."]],
     "outro":[["LOOP","One word got through. 'DISPATCHER.' Somebody inside the tower is arguing with the tower."],["DEALER","The case never went to the wrong door. Someone routed it to the only door that would open it."],["ZIP","Then someone wants us to win. I hate how nice that sounds."]]},
    {"title":"CHAPTER 4 / LAST FREIGHT",
     "intro":[["RIVET","The yard. That crane arm was built to carry whole houses. Remember that when it comes down."],["HUSH","There is a tape reel in the cab marked COMMAND. That is what they are guarding."]],
     "outro":[["HUSH","Playing the tape."],["DISPATCHER","Unit nine, this is the dispatcher. The maintenance signal converts to eviction order at dawn. I cannot stop it from the inside. I sent you the keys. Broadcast this tape on the open avenue before sunrise."],["LOOP","That is an eviction order wearing a maintenance badge. We are going to broadcast it."]]},
    {"title":"CHAPTER 5 / OPEN CHANNEL",
     "intro":[["LOOP","The avenue mast is the loudest point in the district. I need three minutes and a clear road."],["RIVET","Captains protect the jammer crews. Cut the crews first, then the captains."]],
     "outro":[["LOOP","Live. The whole district just heard the tape. People are on their balconies."],["HUSH","The tower noticed. Something large is waking under the signal mast."],["DISPATCHER","I can hold the channel open until dawn. After that you are on your own. Good luck, Afterhours."]]},
    {"title":"CHAPTER 6 / AFTERHOURS",
     "intro":[["DEALER","The tower is not a building. It is a habit. Break the habit and the rest falls over."],["HUSH","Last service. Hold the line until the sun comes up."]],
     "outro":[]}]
## One radio line for every encounter, shown as a short caption when the fight starts and as the
## "next up" line while the player chooses whether to keep going.
const ENCOUNTERS=[
    ["HUSH","Suits at the door. Three of them. They want the case quietly, so make it loud."],
    ["LOOP","Relay is on the noodle shop roof. Push them off the alley and I can climb. A body thrown into a crowd saves time."],
    ["RIVET","That's the relay box. Don't hit it. Hit what's standing next to it."],
    ["ZIP","Toll gate ahead. Pay with your fists. Mind the shields."],
    ["RIVET","Shield wall faces forward. Grab, break the guard, or wait for them to tire."],
    ["LOOP","Last toll booth. Their dispatch is leaking. Keep going while I copy it."],
    ["HUSH","Jammer under the bridge. It marks the ground first. Leave the mark."],
    ["LOOP","The jammer crew is panicking. Their mark is on you, so move."],
    ["ZIP","Last gate under the flyover. After this, the freight yard."],
    ["RIVET","Freight yard. Heavy troopers here. They hit slow, so do not stand there to find out."],
    ["HUSH","Reel in the cab. Don't lose the tape."],
    ["RIVET","Gantry Warden. Knee, shot, core. Nobody is a hero tonight."],
    ["LOOP","I broadcast from the avenue mast. Three minutes and a clear road."],
    ["HUSH","Captains on the avenue. Cut the crews first."],
    ["ZIP","Road capacitors lit. Keep moving. Standing still is how people get lit up."],
    ["DEALER","Courtesy of the house: they get tired. The tower is just a very large habit."],
    ["HUSH","The Leviathan eats the stolen channel. Never give it a steady rhythm."],
    ["ZIP","Last service. Hold the line until the sun comes up."]]
const BOSS_ENTRANCES={
    11:[["RIVET","Gantry Warden. Built to carry homes, taught to take them back."],["HUSH","Tall slam leaves a mark. Low sweep you jump. Expose the core with the knee or a reflected bolt."]],
    17:[["LOOP","That's the Signal Leviathan. It is made of every voice they deleted."],["HUSH","Three rhythms. Break the legs, return the shots, strike the core."],["@","Then I'll give it a new rhythm."]]}
## Endings. Selection lives in ending_for(); the true scene is appended when every technique record is held.
const ENDINGS={
    "open":{"name":"OPEN CHANNEL","lines":[["HUSH","Dawn. The channel is open and nobody turned it off."],["LOOP","Eight thousand receivers. We counted twice."],["RIVET","The eviction order is gone. The notice board says NOTICE WITHDRAWN. Someone drew a smile on it."],["ZIP","Courier app wants a five star review."],["DISPATCHER","Delivery confirmed. Signal keys: returned to their owners."]]},
    "loud":{"name":"LOUD NIGHT","lines":[["LOOP","We never went quiet. We turned every speaker on Old Pier Road to face the street."],["ZIP","Tower security asked us to lower the volume."],["RIVET","I said no."],["HUSH","The block did not sleep. Nobody complained."],["DISPATCHER","Noise complaint received. Filed under 'celebration'."]]},
    "steady":{"name":"STEADY HANDS","lines":[["HUSH","Nobody was left behind. Not on the avenue, not under the bridge."],["RIVET","Patched every shutter. Counted every neighbour."],["LOOP","The broadcast was a roll call. All present."],["ZIP","Slow won for once."],["DISPATCHER","Casualty report for this district: none. I checked three times."]]},
    "salvage":{"name":"SCRAP HOME","lines":[["RIVET","The Warden's frame is already on our roof. Good steel."],["LOOP","Leviathan speakers, mine. Do not ask."],["HUSH","The hub reopens at midday with a new roof and old trains."],["ZIP","Ours."],["DISPATCHER","Tower property written off as scrap. The paperwork is beautiful."]]}}
const TRUE_SCENE=[
    ["DISPATCHER","One more thing. You never needed the keys. You needed each other. Every technique you used tonight is on file in my head."],
    ["DEALER","Free advice, last of the night: keep the radio on."],
    ["LOOP","Next service?"],
    ["ZIP","Next service is ours."]]
const HERO_CLOSING={
    0:"ZIP: Delivered. Signed for. For once the right door.",
    1:"RIVET: Hands steady. Roof fixed. Somebody put the kettle on.",
    2:"HUSH: Quiet. Not silent. There is a difference now.",
    3:"LOOP: Still live. Still plugged in. Still not licking contacts."}
const TECHNIQUE_COUNT=5

static func chapter_of(room:int) -> int:return clampi(floori(float(room)/3.0),0,5)
static func encounter(room:int) -> Array:return ENCOUNTERS[clampi(room,0,17)]
static func hero_name(hero:int) -> String:return HEROES[clampi(hero,0,3)]
static func render(line:Array,hero:int) -> Dictionary:
    var name:String=hero_name(hero) if str(line[0])=="@" else str(line[0])
    return {"speaker":name,"text":str(line[1]).replace("{hero}",hero_name(hero)),"header":str(line[2]) if line.size()>2 else "","color":VOICE_COLORS.get(name,"f7f9fa")}
static func cards(lines:Array,hero:int,header:="") -> Array:
    var result:Array=[]
    for line in lines:result.append(render(line,hero))
    if not result.is_empty() and header!="" and result[0].header=="":result[0].header=header
    return result
## Which ending the run earned. `tally` counts route choices made this expedition.
static func ending_for(tally:Dictionary) -> String:
    var loud:=int(tally.get("hazard",0));var steady:=int(tally.get("rest",0));var salvage:=int(tally.get("cache",0))
    var best:=maxi(loud,maxi(steady,salvage))
    if best<4:return "open"
    if loud==best:return "loud"
    if steady==best:return "steady"
    return "salvage"
static func ending_cards(id:String,hero:int,true_ending:bool) -> Array:
    var entry:Dictionary=ENDINGS.get(id,ENDINGS.open)
    var result:Array=cards(entry.lines,hero,"ENDING / "+str(entry.name))
    if true_ending:result.append_array(cards(TRUE_SCENE,hero,"TRUE ENDING / AFTERHOURS"))
    var closing:String=HERO_CLOSING[clampi(hero,0,3)]
    var parts:=closing.split(": ",true,1)
    result.append({"speaker":parts[0],"text":parts[1],"header":"","color":VOICE_COLORS.get(parts[0],"f7f9fa")})
    return result
