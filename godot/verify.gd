extends SceneTree
func _initialize():
    var expected = {"PROP_HYDRANT_A01": 1477, "PROP_BIN_A01": 1456, "VEH_VAN_A01": 1582, "VEH_CAR_A01": 1524, "PROP_SHOP_STOOL_A01": 1513, "PROP_CRATES_A01": 1491, "PROP_MAILBOX_A01": 1440}
    var results = []
    for asset_id in expected:
        var packed = load("res://scenes/" + asset_id + ".tscn") as PackedScene
        if packed == null:
            quit(1)
            return
        var asset = packed.instantiate()
        root.add_child(asset)
        var meshes = asset.find_children("*", "MeshInstance3D", true, false)
        var collisions = asset.find_children("*", "CollisionShape3D", true, false)
        var triangles = 0
        for mesh in meshes:
            triangles += mesh.mesh.get_faces().size() / 3
        if triangles != expected[asset_id] or collisions.size() == 0:
            push_error("Asset verification failed: " + asset_id)
            quit(1)
            return
        results.append({"asset_id":asset_id,"triangles":triangles,"collisions":collisions.size()})
    var review = load("res://scenes/review.tscn") as PackedScene
    if review == null:
        quit(1)
        return
    root.add_child(review.instantiate())
    print("PROP_LIBRARY_VERIFIED ", JSON.stringify(results))
    quit(0)
