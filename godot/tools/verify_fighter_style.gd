extends SceneTree
const Style=preload("res://scripts/combat/fighter_effect_style.gd")
var checks:Array=[]
var s:Node
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("FIGHTER_STYLE ",label," ",ok)
func run() -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.progression_path=""
    root.add_child(s);s.set_process(false);s.set_physics_process(false)
    await process_frame;await RenderingServer.frame_post_draw
    var audio_hashes:Array=[];var shape_hashes:Array=[];var camera_positions:Array=[]
    for character in 4:
        s.return_to_title();s.set_character(0,character);s.set_character(1,character);s.start_match(true)
        s.sim.phase="fight";s.sim.ai_enabled=false;s.sim.fighters[0].x=-.65;s.sim.fighters[1].x=.65
        var snapshot:String=JSON.stringify(s.sim.fighters)
        var finite:=true;var bounded:=true
        for reduced in [false,true]:
            for kind in ["hit","release","wall","swing","charge","parry","guard_break"]:
                for time in [0.0,.12,.5,.99,1.0]:
                    var marks:Array=Style.marks(character,kind,time,.8,reduced)
                    bounded=bounded and marks.size()<=3
                    for mark in marks:
                        for point in mark.points:
                            finite=finite and point.is_finite()
                            bounded=bounded and point.length()<100
        check("Bounded finite geometry hero %d"%character,finite and bounded)
        shape_hashes.append(JSON.stringify(Style.marks(character,"hit",.12,.8,false)).sha256_text())
        var stream:AudioStreamWAV=s.audio._fighter_tone(character)
        audio_hashes.append(stream.data.hex_encode().sha256_text())
        stream.save_to_wav(OS.get_cmdline_user_args()[0].get_base_dir()+"/"+Style.NAMES[character]+".wav")
        var peak:=0;var energy:=0.0
        for i in int(stream.data.size()/2.0):
            var sample:int=stream.data.decode_s16(i*2);peak=maxi(peak,absi(sample));energy+=float(sample)*sample
        check("Non-silent bounded PCM hero %d"%character,peak>1000 and peak<32767 and energy>0)
        check("Deterministic PCM hero %d"%character,stream.data==s.audio._fighter_tone(character).data)
        for side in 2:
            s.neon.clear();s.neon.mode="CHARGE";s.neon.duration=1.5;s.neon.age=.4;s.neon.signature=true;s.neon.owner=side
            s._process(1.0/60)
            check("Two bodies within HUD margins hero %d owner %d"%[character,side],s.signature_camera.fits(s.camera,s))
            if side==0:camera_positions.append(s.camera.position)
        var all_bounds:=true
        var saved:Array=s.sim.fighters.duplicate(true)
        for gap in [1.3,10.0,19.0]:
            for altitude in [0.0,3.0,7.0]:
                for side in 2:
                    s.sim.fighters[0].x=-gap*.5;s.sim.fighters[1].x=gap*.5;s.sim.fighters[side].y=altitude;s.sim.fighters[1-side].y=0
                    s.neon.clear();s.neon.mode="RELEASE";s.neon.duration=1.0;s.neon.age=.2;s.neon.signature=true;s.neon.owner=side
                    s._process(1.0/60)
                    all_bounds=all_bounds and s.signature_camera.fits(s.camera,s)
        s.sim.fighters.assign(saved)
        check("Eighteen spread/air signature bounds hero %d"%character,all_bounds)
        s.screen="pause"
        var frozen_age:float=s.neon.age;s._process(.2)
        check("Pause freezes director hero %d"%character,s.neon.age==frozen_age)
        s.screen="play"
        s.neon.clear();s.reduced_effects=true;s._process(1.0/60)
        check("F2 exits signature camera hero %d"%character,s.camera.fov==48.0 and not s.neon.active())
        s.reduced_effects=false
        s.audio.contact_budget=0;s.audio.muted=true
        var before:int=s.audio.contact_layers_played;s.audio.play_contact_layer(character,"jab",.5)
        check("Intentional mute respected hero %d"%character,s.audio.contact_layers_played==before)
        s.audio.muted=false;s.audio.effects_level=0;s.audio.play_contact_layer(character,"jab",.5)
        check("Zero effects level respected hero %d"%character,s.audio.contact_layers_played==before)
        s.audio.effects_level=.85;s.audio.play_contact_layer(character,"jab",.5);s.audio.play_contact_layer(character,"jab",.5)
        check("One accent per contact budget hero %d"%character,s.audio.contact_layers_played==before+1)
        check("Presentation leaves simulation untouched hero %d"%character,JSON.stringify(s.sim.fighters)==snapshot)
    check("Four distinct silhouettes",{shape_hashes[0]:true,shape_hashes[1]:true,shape_hashes[2]:true,shape_hashes[3]:true}.size()==4)
    check("Four distinct PCM families",{audio_hashes[0]:true,audio_hashes[1]:true,audio_hashes[2]:true,audio_hashes[3]:true}.size()==4)
    check("Four distinct signature positions",camera_positions[0]!=camera_positions[1] and camera_positions[1]!=camera_positions[2] and camera_positions[2]!=camera_positions[3])
    var failures:=0
    for row in checks:
        if not row.passed:failures+=1
    FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failures,"failed":failures,"pcm_sha256":audio_hashes,"shape_sha256":shape_hashes},"  "))
    s.return_to_title();s.queue_free()
    var layer:=CanvasLayer.new();layer.layer=1000;root.add_child(layer)
    var card:=Control.new();layer.add_child(card)
    card.draw.connect(func():
        card.draw_rect(Rect2(0,0,960,540),Color("111723"))
        var font:=ThemeDB.fallback_font
        for character in 4:
            var x:float=120+character*240
            card.draw_string(font,Vector2(x-85,70),["ZIP / ROUTE","RIVET / STAMP","HUSH / CUT","LOOP / SIGNAL"][character],HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)
            for row in 2:
                Style.draw(card,Vector2(x,185+row*190),{"character":character,"kind":"hit","age":.02,"life":.16,"strength":.85,"face":1,"color":Color("00d6d8")},row==1)
            card.draw_string(font,Vector2(x-65,490),"F2 / REDUCED",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("aab3c0"))
    )
    card.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0].get_base_dir()+"/silhouettes.png")
    layer.queue_free();await process_frame;quit(0 if failures==0 else 1)
