extends RefCounted
## Picture-first station pages (SKILLS, RADIO/story, DEPART). The hub still owns state and save calls;
## these functions only lay out what it already knows, and every button carries meta "act" for tests.
const T=preload("res://scripts/combat/ui/ui_theme.gd")
const W=preload("res://scripts/combat/city/hub_widgets.gd")
const Profile=preload("res://scripts/combat/city/city_profile.gd")
const HEROES=["ZIP","RIVET","HUSH","LOOP"]
const HERO_TINT=[Color("00d6e7"),Color("ff8a00"),Color("bdff00"),Color("ff008c")]
const BASIC_ICONS={"double_jump":"double_jump","launcher":"launcher","chase":"chase","finisher":"finisher","overdrive":"overdrive"}
const BASIC_INFO={"double_jump":"Jump twice before landing.","launcher":"Hit up: launch the enemy.","chase":"Spend energy to chase a launched enemy.","finisher":"Slam down from the air.","overdrive":"W + L big move."}
const BASIC_SHORT={"double_jump":"2x JUMP","launcher":"LAUNCH","chase":"CHASE","finisher":"SLAM","overdrive":"BURST"}
const TECH_ICONS=["fist","kick","ring"]
const TECH_STAGE=[9,12,15]
const DISTRICT_SHORT=["ALLEY","GATE","PASS","YARD","LOCK","TOWER"]
const ROUTE_ICON={"combat":"swords","cache":"box","hazard":"bolt","rest":"bed"}
const ROUTE_NAME={"combat":"FIGHT","cache":"LOOT","hazard":"RISK","rest":"REST"}
const ROUTE_INFO={"combat":"Normal fight, normal loot.","cache":"Extra heavy enemy and one extra item.","hazard":"Charged street: +20% credits, more danger.","rest":"Heal 20 HP once."}

static func skills(hub:Node) -> void:
    var p=hub.campaign.profile
    var hero_id:int=hub.campaign.hero_id()
    var tint:Color=HERO_TINT[hero_id]
    W.head(hub,"fist",HEROES[hero_id]+" SKILLS",tint)
    var rank:=int(p.data.skill_levels[hero_id])
    # L skill rank: one line with pips, price chips and the upgrade button.
    var card:=PanelContainer.new();card.add_theme_stylebox_override("panel",T.plate(Color("10121f"),tint,2));hub.stack.add_child(card)
    var line:=HBoxContainer.new();line.add_theme_constant_override("separation",10);line.alignment=BoxContainer.ALIGNMENT_CENTER;card.add_child(line)
    line.add_child(W._small("fist",tint));line.add_child(W.label("L",28,T.PAPER,false,false))
    var states:=[];for i in 3:states.append(1 if i<rank else 0)
    W.pips(hub,states,tint,line)
    var spacer:=Control.new();spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;line.add_child(spacer)
    W.chip("coin","30",T.LIME,line);W.chip("gear",str(2+rank),T.TEAL,line)
    var up:=W.cta(hub,"arrow","UP",tint,func():hub.act(func():return p.upgrade_skill(hero_id),"Class skill upgraded"),rank>=3 or p.data.credits<30 or p.data.parts<2+rank,"upgrade_l","L skill rank up: +5% basic L damage.")
    up.get_parent().remove_child(up);line.add_child(up);up.custom_minimum_size=Vector2(120,52)
    W.section(hub,"star","BASICS")
    var g:=W.grid(hub,5)
    for skill in Profile.SKILLS:
        var id:String=skill.id
        var owned:bool=id in p.data.skills
        var open:bool=int(p.data.best)>=int(skill.at)
        var state:="owned" if owned else ("ready" if open else "locked")
        var sub:="TRY" if owned else ("LEARN" if open else "STAGE %d"%int(skill.at))
        var cb:Callable=(func():hub.campaign.start_lesson(id)) if owned else (func():hub.act(func():return p.learn(id),"Skill learned"))
        var t:=W.tile(hub,BASIC_ICONS[id],BASIC_SHORT[id],sub,tint,state,cb,str(skill.name)+": "+BASIC_INFO[id]+(" Tap to practice." if owned else ""),("practice:" if owned else "learn:")+id)
        W.into(g,t)
    W.section(hub,"ring","TECHNIQUES %d / 2"%p.data.advanced[hero_id].size())
    var g2:=W.grid(hub,3)
    for i in 3:
        var skill:Dictionary=p.Advanced.SKILLS[hero_id][i];var id:String=skill.id
        var owned:bool=id in p.data.advanced[hero_id]
        var open:bool=int(p.data.best)>=TECH_STAGE[i]
        var full:bool=not owned and p.data.advanced[hero_id].size()>=2
        var state:="owned" if owned else ("locked" if not open else ("off" if full else "ready"))
        var sub:="ON" if owned else ("STAGE %d"%TECH_STAGE[i] if not open else ("FULL" if full else "EQUIP"))
        var t:=W.tile(hub,TECH_ICONS[i],str(skill.name),sub,tint,state,func():hub.act(func():return p.advanced_skill(hero_id,id),"Class technique updated"),str(skill.desc)+(" Tap to remove." if owned else ""),"tech:"+id)
        if state=="off":t.disabled=true
        W.into(g2,t)

static func story(hub:Node) -> void:
    var p=hub.campaign.profile
    var current:int=p.Story.chapter(int(p.data.best))
    var chapter:int=current if hub.chapter_review<0 else mini(current,hub.chapter_review)
    var entry:Dictionary=p.Story.CHAPTERS[chapter]
    W.head(hub,"radio","STORY",hub.COLORS[3])
    # Chapter strip: done / current / locked at a glance.
    var strip:=HBoxContainer.new();strip.add_theme_constant_override("separation",6);hub.stack.add_child(strip)
    for i in 6:
        var index:=i
        var done:bool=int(p.data.best)>=(i+1)*3
        var open:bool=i<=current
        var state:="active" if i==chapter else ("owned" if done else ("ready" if open else "locked"))
        var t:=W.tile(hub,"check" if done else "flag",str(i+1),"",T.CORAL,state,func():hub.chapter_review=(-1 if index==current else index);hub.open_station(3),str(p.Story.CHAPTERS[i].title) if open else "Locked",("chapter:%d"%(i+1)),Vector2(70,84))
        W.into(strip,t)
    var title:String=str(entry.title)
    var parts:=title.split(" / ")
    W.head_title(hub,parts[1] if parts.size()>1 else title,T.CORAL)
    # One speaker at a time, shown as a portrait row.
    var talk:=HBoxContainer.new();talk.add_theme_constant_override("separation",6);hub.stack.add_child(talk)
    var faces=["keeper","dealer","mechanic"];var names=["KEEPER","FIXER","MECHANIC"]
    for i in 3:
        var index:=i
        var t:=W.tile(hub,faces[i],names[i],"",hub.COLORS[3],"active" if hub.speaker==i else "ready",func():hub.speaker=index;hub.open_station(3),"","speaker:%d"%i,Vector2(0,86))
        W.into(talk,t)
    var bubble:=PanelContainer.new();bubble.add_theme_stylebox_override("panel",T.plate(Color("10121f"),T.PAPER,2));hub.stack.add_child(bubble)
    var words:String=p.Story.dialogue(int(p.data.best),hub.speaker) if hub.chapter_review<0 else str(entry.intro)
    var split:=words.find(": ");bubble.add_child(W.label(words.substr(split+2) if split>=0 else words,20,T.PAPER))
    var mission:=HBoxContainer.new();mission.add_theme_constant_override("separation",8);hub.stack.add_child(mission)
    mission.add_child(W._small("pin",T.LIME));var ml:=W.label(str(entry.objective),20,T.LIME);ml.size_flags_horizontal=Control.SIZE_EXPAND_FILL;mission.add_child(ml)
    # Technique journal: five icons, tick when claimed.
    W.section(hub,"book","MOVES")
    var journal:=HBoxContainer.new();journal.add_theme_constant_override("separation",6);hub.stack.add_child(journal)
    var jicon={"parry":"shield","chain":"swords","chase":"chase","finisher":"finisher","boss":"skull"}
    var jname={"parry":"PARRY","chain":"CHAIN","chase":"CHASE","finisher":"SLAM","boss":"BOSS"}
    for id in p.Story.TECHNIQUES:
        var done:bool=id in p.data.quest_claims
        var t:=W.tile(hub,"check" if done else jicon[id],"","",T.TEAL,"owned" if done else "plain",Callable(),str(p.Story.TECHNIQUES[id]),"move:"+str(id),Vector2(64,64))
        t.disabled=false;t.focus_mode=Control.FOCUS_ALL
        W.into(journal,t)
    # Boss practice.
    var bosses:=HBoxContainer.new();bosses.add_theme_constant_override("separation",8);hub.stack.add_child(bosses)
    var b1:=W.tile(hub,"skull","WARDEN","TRY" if p.data.best>=9 else "STAGE 9",T.CORAL,"ready" if p.data.best>=9 else "locked",func():hub.campaign.start_lesson("boss","gantry"),"Practice the Gantry Warden. No loot.","practice:boss_gantry",Vector2(0,86))
    var b2:=W.tile(hub,"skull","LEVIATHAN","TRY" if p.data.best>=15 else "STAGE 15",T.CORAL,"ready" if p.data.best>=15 else "locked",func():hub.campaign.start_lesson("boss","signal"),"Practice the Signal Leviathan. No loot.","practice:boss_signal",Vector2(0,86))
    W.into(bosses,b1);W.into(bosses,b2)
    if not p.data.last_loot.is_empty():
        var loot:=HBoxContainer.new();loot.add_theme_constant_override("separation",6);hub.stack.add_child(loot)
        loot.add_child(W._small("bag",T.LIME))
        var ll:=W.label(", ".join(p.data.last_loot.map(func(r)->String:return str(r))),18,T.LIME);ll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;loot.add_child(ll)

static func depart(hub:Node) -> void:
    var p=hub.campaign.profile
    var chapter:int=p.Story.chapter(int(p.data.best))
    W.head(hub,"arrow","DEPART",hub.COLORS[4])
    var d:Dictionary=p.data
    if not d.run.is_empty():
        var run:Dictionary=d.run
        var contract:bool=run.get("mode","story")=="contract"
        var stats:=HBoxContainer.new();stats.add_theme_constant_override("separation",14);hub.stack.add_child(stats)
        W.bar(hub,float(run.hp),100.0,T.CORAL,"heart",stats)
        W.bar(hub,float(run.meter),100.0,T.TEAL,"bolt",stats)
        var core:=HBoxContainer.new();core.add_theme_constant_override("separation",10);hub.stack.add_child(core)
        if not str(run.get("core","NONE")) in ["NONE",""]:
            W.chip("core",str(run.get("core")).to_upper(),T.LIME,core)
        if contract:
            W.chip("star","T%d"%int(run.contract.tier),T.LIME,core)
            var waves:Array=[];for i in int(run.contract.waves):waves.append(2 if i==int(run.wave) else (1 if i<int(run.wave) else 0))
            W.pips(hub,waves,T.TEAL)
            var tries:=HBoxContainer.new();tries.add_theme_constant_override("separation",4);hub.stack.add_child(tries)
            for i in int(run.tries):tries.add_child(W._small("heart",T.CORAL))
            tries.tooltip_text="Attempts left"
        else:
            var room:=int(run.room)
            var states:Array=[];for i in 18:states.append(1 if i<room else (2 if i==room else 0))
            W.pips(hub,states,T.TEAL,null,3)
            var where:=HBoxContainer.new();where.add_theme_constant_override("separation",8);hub.stack.add_child(where)
            W.chip("pin",Profile.DISTRICTS[mini(5,floori(float(room)/3.0))]+"  %d/3"%(room%3+1),T.LIME,where)
        if run.boon_due:
            W.section(hub,"star","PICK ONE",T.LIME)
            var row:=HBoxContainer.new();row.add_theme_constant_override("separation",6);hub.stack.add_child(row)
            var kinds={"damage":["fist","DAMAGE"],"defence":["shield","GUARD"],"economy":["coin","CASH"]}
            for stat in ["damage","defence","economy"]:
                var id:String=stat
                var gain:int=roundi(p.boon_gain(id)*100)
                W.into(row,W.tile(hub,kinds[stat][0],kinds[stat][1],"+%d%%"%gain,T.LIME,"ready" if gain>0 else "locked",func():hub.act(func():return p.choose_boon(id),"Current absorbed"),"Salvaged current. Actual gain shown after caps. Lost on defeat.","boon:"+id,Vector2(0,104)))
            W.into(row,W.tile(hub,"coin","SKIP","+10",T.LIME,"ready",func():hub.act(p.skip_boon,"Current exchanged"),"Take 10 credits instead.","boon:skip",Vector2(0,104)))
        if run.get("route_due",false):
            W.section(hub,"arrow","NEXT",T.TEAL)
            var rg:=W.grid(hub,3)
            for route in p.route_options():
                var id:String=route
                W.into(rg,W.tile(hub,ROUTE_ICON[route],ROUTE_NAME[route],"",T.TEAL,"ready",func():hub.act(func():return p.choose_route(id),"Route committed"),ROUTE_INFO[route],"route:"+id,Vector2(0,104)))
        W.cta(hub,"play","GO",T.LIME,hub.campaign.depart,bool(run.boon_due),"depart","Continue the expedition.")
        var end:=W.tile(hub,"close","END RUN","",T.CORAL,"ready",func():hub.act(p.abandon,"Expedition ended; temporary current cleared"),"Ends this expedition. Credits, gear, skills and talents stay.","end_run",Vector2(0,56),true)
    else:
        W.section(hub,"flag","DISTRICT",T.TEAL)
        var g:=W.grid(hub,3)
        for i in 6:
            var sector:=i
            var open:bool=i<=mini(5,floori(float(d.best)/3.0))
            var done:int=clampi(int(d.best)-i*3,0,3)
            var state:="locked" if not open else ("owned" if done>=3 else "ready")
            var t:=W.tile(hub,"check" if done>=3 else "pin",str(i+1)+" "+DISTRICT_SHORT[i],"" if not open else "",T.CORAL,state,func():
                if p.start_run(hub.campaign.hero_id(),sector):hub.campaign.depart(),Profile.DISTRICTS[i]+(" / cleared %d of 3"%done if open else " / locked"),"sector:%d"%i,Vector2(0,96))
            W.into(g,t)
            if open:
                var box:Control=t.get_child(0)
                var pips:=[];for k in 3:pips.append(1 if k<done else 0)
                var holder:=CenterContainer.new();holder.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(holder)
                W.pips(hub,pips,T.TEAL,holder)
        W.section(hub,"hero","HERO")
        var row:=HBoxContainer.new();row.add_theme_constant_override("separation",6);hub.stack.add_child(row)
        for i in 4:
            var index:=i
            W.into(row,W.tile(hub,"hero",HEROES[i],"",HERO_TINT[i],"active" if hub.campaign.selected_hero==i else "ready",func():hub.campaign.selected_hero=index;hub.open_station(4),"Play as "+HEROES[i],"hero:%d"%i,Vector2(0,56),true))
        W.cta(hub,"play","GO",T.LIME,hub.campaign.depart,false,"depart","Start at the newest district.")
        if int(d.best)>=18:
            W.section(hub,"skull","CONTRACTS  T%d"%int(d.contract_tier),T.LIME)
            var cg:=W.grid(hub,2)
            for contract in d.contracts:
                var id:=int(contract.id)
                var stars:String="*".repeat(int(contract.tier))
                var t:=W.tile(hub,"skull" if int(contract.tier)==5 else "swords","T%d  %s"%[int(contract.tier),DISTRICT_SHORT[int(contract.sector)]],"%d WAVES"%int(contract.waves),T.LIME,"ready",func():
                    if p.start_contract(hub.campaign.hero_id(),id):hub.campaign.depart(),p.Contracts.describe(contract),"contract:%d"%id,Vector2(0,104))
                W.into(cg,t)
