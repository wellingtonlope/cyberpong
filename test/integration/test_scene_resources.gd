extends GutTest

const SCENE_PATHS := [
	"res://main.tscn",
	"res://scenes/ball.tscn",
	"res://scenes/paddle.tscn",
	"res://scenes/game_menu.tscn",
]


func test_project_scenes_load_all_external_resources() -> void:
	for scene_path in SCENE_PATHS:
		var scene: PackedScene = load(scene_path)
		assert_not_null(scene, "Falha ao carregar %s" % scene_path)
		if scene == null:
			continue
		var instance := scene.instantiate()
		assert_not_null(instance, "Falha ao instanciar %s" % scene_path)
		if instance != null:
			instance.free()


func test_fallback_font_is_available_without_external_font_assets() -> void:
	var font := ThemeDB.fallback_font
	assert_not_null(font)
	assert_gt(font.get_height(24), 0.0)
