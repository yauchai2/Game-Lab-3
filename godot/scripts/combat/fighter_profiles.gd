extends RefCounted
## Deterministic per-character move and movement data; no cosmetic hit bonuses.
const PROFILES := [
    {"trait":"trait_boxer","speed":1.0,"gain":1.0,"color":"ff6a00","special_name":"skill_boxer","overdrive_name":"cannon_boxer"},
    {"trait":"trait_dancer","speed":1.08,"gain":1.0,"color":"4acfe0","special_name":"skill_dancer","overdrive_name":"cannon_dancer"},
    {"trait":"trait_bass","speed":.91,"gain":.94,"color":"e05aaf","special_name":"skill_bass","overdrive_name":"cannon_bass"},
    {"trait":"trait_spark","speed":1.14,"gain":1.12,"color":"d7f400","special_name":"skill_spark","overdrive_name":"cannon_spark"},
]
static func profile(index:int) -> Dictionary:
    return PROFILES[clampi(index,0,3)]
static func move(base:Dictionary,index:int,name:String) -> Dictionary:
    var m:Dictionary=base.duplicate()
    match index:
        1:
            if name in ["cross","finisher","air_kick","launcher"]:m.reach+=.25
            if name in ["air_jab","air_kick"]:m.recovery=maxi(8,m.recovery-2)
            if name=="launcher":m.lift=11.0
            if name=="special":m.damage=24;m.reach=3.8;m.startup=16;m.push=12.0
            if name=="overdrive":m.damage=34;m.reach=4.1;m.lift=10.0
        2:
            if name in ["cross","finisher","heavy","grab"]:m.damage+=2;m.startup+=1 if name=="cross" else 2
            if name in ["finisher","heavy","grab"]:m.push+=1.0
            if name in ["launcher","air_jab","air_kick"]:m.reach+=.2
            if name=="special":m.damage=31;m.startup=22;m.reach=3.2;m.push=16.0
            if name=="overdrive":m.damage=43;m.startup=34;m.reach=3.5;m.push=20.0
        3:
            if name in ["jab","cross","air_jab","air_kick"]:m.startup=maxi(3,m.startup-1);m.damage=maxi(4,m.damage-1)
            if name=="special":m.damage=22;m.startup=13;m.reach=3.6;m.recovery=25
            if name=="overdrive":m.damage=32;m.startup=24;m.reach=4.3;m.recovery=34
    return m
