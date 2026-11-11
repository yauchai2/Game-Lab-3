extends RefCounted
## One intent per side/contact, counted only by actionable fixed simulation steps.
const LIFETIME := 36
var slots:Array = [{},{}]
var serial := 0
func clear() -> void:
    slots=[{},{}]
func cancel(side:int) -> void:
    slots[side]={}
func open(side:int) -> void:
    serial+=1
    slots[side]={"serial":serial,"left":LIFETIME,"choice":"","spent":false}
func offer(side:int,choice:String) -> bool:
    if slots[side].is_empty() or choice not in ["light","heavy","dash"]:return false
    var slot:Dictionary=slots[side]
    if slot.spent:return false
    if slot.choice=="" and not slot.spent:slot.choice=choice
    return true
func command(side:int,stopped:bool,can_act:bool) -> Dictionary:
    var slot:Dictionary=slots[side]
    if slot.is_empty() or stopped:return {}
    slot.left-=1
    var result:Dictionary={}
    if can_act and slot.choice!="" and not slot.spent:
        slot.spent=true
        result={"dash":true} if slot.choice=="dash" else {"attack":slot.choice}
        if slot.choice=="heavy":result["up"]=true
    if slot.left<=0:cancel(side)
    return result
