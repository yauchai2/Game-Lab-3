extends SceneTree
var checks: Array[Dictionary] = []
var metrics: Dictionary = {}
func _initialize() -> void:
    call_deferred("run")
func check(label: String, condition: bool) -> void:
    checks.append({"name":label,"passed":condition})
    if not condition: push_error("PLAYTEST FIX FAIL: "+label)
func hand_forward(actor: Node3D) -> float:
    var skeleton: Skeleton3D = actor.skeleton
    var left := skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("mixamorig_LeftHand")).origin)
    var right := skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("mixamorig_RightHand")).origin)
    return maxf(left.x,right.x)
func run() -> void:
    var scene := preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    scene.set_process(false)
    scene.set_physics_process(false)
    await process_frame
    var bg: Node3D = scene.backdrop
    check("street and fighters share the same 3D world",bg.street.get_world_3d()==scene.fighters[0].get_world_3d())
    check("no independent viewport or flat background composite remains",bg.find_children("*","SubViewport",true,false).is_empty())
    check("gameplay uses one perspective camera",scene.camera.projection==Camera3D.PROJECTION_PERSPECTIVE)
    check("both street walls remain visible",bg.street.get_node("BuildingMasses/BlueFront").visible and bg.street.get_node("BuildingMasses/OrangeFront").visible)
    check("fighters stand on the crossing depth",is_equal_approx(scene.fighters[0].position.z,3.0) and is_equal_approx(scene.fighters[1].position.z,3.0))
    check("source street stays unrotated",is_zero_approx(bg.street.rotation.y))
    check("street inspection shortcuts do not consume combat keys",not bg.street.is_processing_unhandled_key_input())
    check("left fighter mesh faces the opponent",scene.fighters[0].basis.z.dot(Vector3.RIGHT)>0.99)
    check("right fighter mesh faces the opponent",scene.fighters[1].basis.z.dot(Vector3.LEFT)>0.99)
    scene.sim.phase = "fight"
    scene.sim.ai_enabled = false
    scene.sim.fighters[0].x = 3
    scene.sim.fighters[1].x = -3
    scene.sim.tick()
    scene._present(0.016)
    check("crossing sides reverses the visual facing",scene.fighters[0].basis.z.dot(Vector3.LEFT)>0.99 and scene.fighters[1].basis.z.dot(Vector3.RIGHT)>0.99)
    var center_basis: Basis = scene.camera.basis
    scene.sim.fighters[0].x = -8
    scene.sim.fighters[1].x = -4
    for i in 60: scene._present(1.0/60.0)
    var left_basis: Basis = scene.camera.basis
    check("leftward travel gently changes camera angle",not left_basis.is_equal_approx(center_basis))
    scene.sim.fighters[0].x = 4
    scene.sim.fighters[1].x = 8
    for i in 90: scene._present(1.0/60.0)
    check("rightward travel changes the angle in the opposite direction",scene.camera.basis.z.x>0 and left_basis.z.x<0)
    var projected_a: Vector2 = scene.project(Vector2(4,1))
    var projected_b: Vector2 = scene.project(Vector2(8,1))
    check("both fighters remain inside the camera frame",projected_a.x>0 and projected_b.x<1280 and projected_a.y<660 and projected_b.y<660)
    var visible_labels := 0
    for label in bg.find_children("*","Label3D",true,false):
        if label.is_visible_in_tree(): visible_labels+=1
    check("no scene-space text is visible",visible_labels==0)
    var visible_glyphs := 0
    for mesh in bg.street.get_node("Landmarks").get_children():
        if mesh.name.begins_with("SignGlyphProxy") and mesh.visible: visible_glyphs+=1
    check("legacy geometric text proxies are hidden",visible_glyphs==0)
    check("blank sign panels remain for future textures",bg.street.get_node("Landmarks/VerticalSignFace").visible)
    check("combat HUD remains available",scene.hud.is_visible_in_tree())
    bg.elapsed = 0
    bg.present(0.1,false)
    var first: Vector3 = bg.plane.position
    bg.present(0.1,false)
    var second: Vector3 = bg.plane.position
    bg.present(0.1,false)
    var third: Vector3 = bg.plane.position
    check("aircraft maintains a straight constant-speed path",(second-first).is_equal_approx(third-second) and (second-first).length()>0.1)
    var elapsed_before: float = bg.elapsed
    bg.present(1.0,true)
    check("pause freezes aircraft",bg.elapsed==elapsed_before and bg.plane.position==third)
    bg.present(7.0,false)
    check("aircraft hides during cooldown",not bg.plane.visible)
    bg.freeze_for_capture()
    check("capture restores the fixed aircraft pose",bg.plane.visible and bg.plane.position==bg.anchor)
    # Animation and facing regressions operate on the actual imported skeleton.
    scene.sim.restart_match()
    scene.sim.phase = "fight"
    var actor: Node3D = scene.fighters[0]
    var f: Dictionary = scene.sim.fighters[0]
    for i in 25: actor.present(f,1.0/60.0,false,true)
    check("14 authored CC0 clips are loaded",actor.motions.library.clips.size()==14 and actor.motions.library.license=="CC0-1.0")
    check("body and finger bones are retargeted",actor.motions.mapping.size()>=45)
    var skeleton: Skeleton3D = actor.skeleton
    var hips := skeleton.get_bone_global_pose(skeleton.find_bone("mixamorig_Hips")).origin
    var wrist := skeleton.get_bone_global_pose(skeleton.find_bone("mixamorig_LeftHand")).origin
    check("boxing stance raises the hands above the hips",wrist.y>hips.y+0.10)
    var guard_reach := hand_forward(actor)
    f.state = "attack"
    f.move = "jab"
    f.frame = 5
    for i in 8: actor.present(f,1.0/60.0,false,true)
    var jab_reach := hand_forward(actor)
    metrics["guard_hand_x"] = guard_reach
    metrics["jab_hand_x"] = jab_reach
    check("jab visibly extends a fist toward the opponent",jab_reach>guard_reach+0.08)
    var bone := skeleton.find_bone("mixamorig_LeftArm")
    var frozen_pose := skeleton.get_bone_pose_rotation(bone)
    for i in 6: actor.present(f,1.0/60.0,true,true)
    check("hitstop holds the authored animation pose",frozen_pose.is_equal_approx(skeleton.get_bone_pose_rotation(bone)))
    f.move = "heavy"
    f.frame = 16
    for i in 8: actor.present(f,1.0/60.0,false,true)
    var knee := skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("mixamorig_RightLeg")).origin)
    var foot := skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("mixamorig_RightFoot")).origin)
    check("heavy attack extends the kicking leg forward",foot.x>knee.x+0.15)
    var finite := true
    for clip in actor.motions.library.clips.values():
        for track in clip.tracks.values():
            if not track.has("rotation"): continue
            for t in [0.0,float(clip.duration)*0.5,float(clip.duration)]:
                var rotation: Quaternion = actor.motions._sample_quat(track.rotation,t)
                if not rotation.is_finite() or absf(rotation.length()-1.0)>0.01: finite = false
    check("all imported clip rotation samples are finite and normalized",finite)
    f.state = "idle"
    f.health = 0
    actor.present(f,0.016,false,true)
    actor.present(f,0.1,false,true)
    check("KO can play the death clip after hitstop",actor.motions.clip_name=="Death01" and actor.motions.clip_elapsed>0)
    var walk := preload("res://scenes/street_walk.tscn").instantiate()
    root.add_child(walk)
    var walk_labels := 0
    for label in walk.find_children("*","Label3D",true,false):
        if label.is_visible_in_tree(): walk_labels+=1
    check("walk mode also hides generated scene text",walk_labels==0)
    walk.queue_free()
    scene.queue_free()
    await process_frame
    await process_frame
    # AudioServer releases stopped playbacks on its mixer thread.
    await create_timer(0.10).timeout
    var failed := checks.filter(func(c: Dictionary)->bool: return not c.passed).size()
    var file := FileAccess.open("res://../docs/evidence/playtest-fixes/verification.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"checks":checks,"metrics":metrics,"passed":checks.size()-failed,"failed":failed,"method":"headless scene, actual skeleton poses, perspective framing and authored animation data checks; not human playtesting"},"  "))
    file.close()
    print("PLAYTEST_FIX_CHECKS ",checks.size()-failed,"/",checks.size())
    quit(0 if failed==0 else 1)
