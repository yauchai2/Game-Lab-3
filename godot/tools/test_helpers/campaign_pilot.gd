extends RefCounted
## Test controller using visible tells and ordinary commands, not injected damage.
static func command(s:RefCounted,tick:int,skilled:=true) -> Dictionary:
    var hero:Dictionary=s.fighters[0];var enemy:Dictionary=s.fighters[1]
    var input:Dictionary={"axis":signf(enemy.x-hero.x) if absf(enemy.x-hero.x)>1.25 else 0.0}
    if not skilled:input.rush=true;return input
    var avoid:=false
    for zone in s.campaign_hazards:
        if zone.struck:continue
        if zone.kind=="slam":
            avoid=true;input.axis=-1.0 if hero.x>float(zone.x)-float(zone.half)-.7 else 0.0
        elif zone.kind in ["sweep","street","jammer"]:
            avoid=true
            if int(zone.warn)-int(zone.age)<18 and hero.y<.01 and hero.state=="idle":input.jump=true
        elif zone.kind=="bolt":
            avoid=true
            if int(zone.age)>=int(zone.warn) and absf(float(zone.bolt_x)-hero.x)<2.0:input.guard=true
    if not avoid:
        if enemy.has("boss"):
            if enemy.boss.step!="transition":
                if enemy.boss.open>0:input.rush=true
                elif tick%45==0:input.attack="heavy";input.down=true
        else:
            input.rush=true
            if enemy.guarding and absf(hero.x-enemy.x)<1.2:input.attack="grab"
            elif tick%63==0:input.attack="heavy";input.down=true
    return input

static func full_story(character:int) -> Dictionary:
    var profile=preload("res://scripts/combat/city/city_profile.gd").new();profile.path="";profile.rng.seed=1137+character;profile.start_run(character)
    var rooms:Array=[];var heals:=0
    for room in 18:
        for skill in profile.SKILLS:profile.learn(skill.id)
        for node in profile.Builds.nodes():profile.allocate(character,node.id)
        for perk in profile.Advanced.SKILLS[character]:
            if profile.data.advanced[character].size()<2:profile.advanced_skill(character,perk.id)
        if profile.data.run.hp<75:
            while profile.data.run.hp<90 and profile.data.credits>=25:
                profile.heal();heals+=1
        var sim=preload("res://scripts/combat/story/story_simulation.gd").new();sim.last_service_enabled=true;sim.character_choices=[character,4];sim.difficulty=0;sim.begin_story();sim.campaign_enabled=true;sim.campaign_room=room
        sim.campaign_stats=profile.stats(character);sim.campaign_skills=profile.data.skills.duplicate();sim.service_perks=[profile.data.advanced[character].duplicate(),[]]
        sim.campaign_boss="gantry" if room==11 else ("signal" if room==17 else "")
        sim.wave_recipes=[["boss","grunt","grunt"]] if sim.campaign_boss!="" else [profile.recipe(room)]
        sim._load_wave(0,int(profile.data.run.hp),float(profile.data.run.meter))
        var used:=0
        for tick in 24000:
            sim.tick(command(sim,tick));used=tick
            if sim.story_state in ["complete","failed"]:break
        rooms.append({"room":room,"state":sim.story_state,"hp":sim.fighters[0].health,"ticks":used})
        if sim.story_state!="complete":return {"complete":false,"hero":character,"rooms":rooms,"heals":heals,"credits":profile.data.credits}
        profile.data.run["in_flight"]=true;profile.settle(true,int(sim.fighters[0].health),float(sim.fighters[0].meter))
        if not profile.data.run.is_empty():
            if not profile.choose_boon("damage") and not profile.choose_boon("defence") and not profile.choose_boon("economy"):profile.skip_boon()
            profile.choose_route("combat")
    return {"complete":true,"hero":character,"rooms":rooms,"heals":heals,"credits":profile.data.credits,"xp":profile.data.xp}
