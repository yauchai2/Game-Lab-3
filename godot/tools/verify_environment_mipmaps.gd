extends SceneTree
func _initialize() -> void:
    var paths := ["res://assets/textures/road_asphalt_128.png", "res://assets/textures/sidewalk_tiles_128.png", "res://assets/textures/painted_concrete_128.png"]
    var results := []
    var passed := true
    for path in paths:
        var image: Image = (load(path) as Texture2D).get_image()
        var count := image.get_mipmap_count()
        var ok := image.get_width() == 128 and image.get_height() == 128 and image.has_mipmaps() and count == 7
        results.append({"path": path, "width": image.get_width(), "height": image.get_height(), "mipmap_levels_excluding_base": count, "passed": ok})
        passed = passed and ok
    print("ENVIRONMENT_MIPMAPS ", JSON.stringify({"passed":passed,"textures":results}))
    quit(0 if passed else 1)
