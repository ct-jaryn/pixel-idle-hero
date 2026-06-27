extends SceneTree

var _frame: int = 0
var _main: Node = null

func _initialize() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	_main = main_scene.instantiate()
	root.add_child(_main)

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 10:
		var am: Node = _main.get_node("GameManager/AchievementManager") if _main.has_node("GameManager/AchievementManager") else null
		if am:
			var ach: AchievementData = am.achievements[0]
			var toast: Node = _main.get_node_or_null("AchievementToast")
			if toast:
				toast.show_achievement(ach)
	if _frame == 25:
		var img: Image = get_root().get_texture().get_image()
		img.save_png("res://tools/toast_capture.png")
		print("saved toast_capture.png")
		quit()
	return false
