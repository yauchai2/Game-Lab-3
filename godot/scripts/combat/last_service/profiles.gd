extends RefCounted
const IDS=["zip","rivet","hush","loop"]
const NAMES=["ZIP","RIVET","HUSH","LOOP"]
const PROFILES=[
 {"trait":"trait_zip","speed":1.12,"gain":1.0,"color":"00d6d8","special_name":"skill_zip","overdrive_name":"cannon_zip"},
 {"trait":"trait_rivet","speed":.88,"gain":.95,"color":"ff921c","special_name":"skill_rivet","overdrive_name":"cannon_rivet"},
 {"trait":"trait_hush","speed":.96,"gain":1.02,"color":"ff459d","special_name":"skill_hush","overdrive_name":"cannon_hush"},
 {"trait":"trait_loop","speed":1.0,"gain":1.0,"color":"b8ff00","special_name":"skill_loop","overdrive_name":"cannon_loop"}]
const BLACK_SUIT_PROFILE={"trait":"trait_black_suit","speed":.98,"gain":1.0,"color":"a888ff","special_name":"skill_black_suit","overdrive_name":"cannon_black_suit"}
static func profile(index:int) -> Dictionary:
    return BLACK_SUIT_PROFILE if index==4 else PROFILES[clampi(index,0,3)]
static func move(base:Dictionary,index:int,name:String,f:Dictionary={}) -> Dictionary:
    var m:Dictionary=base.duplicate()
    match index:
        4:
            # A melee enemy, without hero resource mechanics or growth perks.
            if name=="special":m.damage=24;m.startup=18;m.active=6;m.recovery=34;m.reach=2.5;m.push=10.0
            if name=="overdrive":m.damage=38;m.startup=28;m.active=8;m.recovery=44;m.reach=2.8;m.push=16.0
        0:
            if name in ["jab","cross","air_jab","air_kick"]:m.damage=maxi(4,m.damage-1);m.recovery=maxi(8,m.recovery-2)
            if name=="special":m.damage=10 if f.get("service",{}).get("zip_second",false) else 12;m.startup=14;m.active=10;m.recovery=28;m.reach=2.7;m.push=8.0 if f.get("service",{}).get("zip_second",false) else 2.0
            if name=="overdrive":m.damage=15 if f.get("service",{}).get("flurry_left",2)==0 else 13;m.startup=24;m.active=17;m.recovery=34;m.reach=3.0;m.push=15.0 if f.get("service",{}).get("flurry_left",2)==0 else 2.0;m.lift=3.0
        1:
            if name in ["cross","heavy","finisher"]:m.damage+=3;m.startup+=2
            if name=="special":
                var tier:int=f.get("service",{}).get("preload",0)
                m.damage=23+tier*5;m.startup=24;m.active=6;m.recovery=38 if "rivet_recover" in f.get("perks",[]) and tier>=2 else 42;m.reach=2.6;m.push=12.0+tier*3
            if name=="overdrive":m.damage=46;m.startup=38;m.reach=2.9;m.recovery=52;m.push=20.0
        2:
            if name=="special":m.damage=19;m.startup=11;m.active=5;m.recovery=30;m.reach=2.6;m.push=7.0
            if name=="overdrive":m.damage=35;m.startup=22;m.active=6;m.recovery=40;m.reach=2.7;m.push=14.0
            if f.get("service",{}).get("sample_boost",false) and name in ["cross","heavy","launcher","special","overdrive"]:m.damage+=3;m.push+=3.0
            if "hush_recover" in f.get("perks",[]) and f.get("service",{}).get("sample_boost",false):m.recovery=maxi(8,m.recovery-4)
        3:
            if name=="jab":m.reach=1.9;m.push=2.8
            if name=="cross":m.reach=2.0;m.push=3.4
            if name=="special":m.damage=0;m.reach=0.0;m.startup=14;m.active=1;m.recovery=20
            if name=="overdrive":m.damage=24;m.startup=28;m.active=12;m.recovery=44;m.reach=2.5
    return m
