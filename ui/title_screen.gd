extends Control

@onready var continue_button: Button = %ContinueButton
@onready var new_game_button: Button = %NewGameButton
@onready var exit_button: Button = %ExitButton

var save_manager: SaveManager = SaveManager.new()

func _ready() -> void:
	continue_button.visible = save_manager.has_save()
	if OS.has_feature("web"):
		exit_button.visible = false
	
	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	## 设置初始焦点，改善手柄/键盘导航体验
	if continue_button.visible:
		continue_button.grab_focus()
	else:
		new_game_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	## 手柄/键盘方向键在按钮间移动焦点
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up"):
		var focused: Control = get_viewport().gui_get_focus_owner()
		if focused == null:
			if continue_button.visible:
				continue_button.grab_focus()
			else:
				new_game_button.grab_focus()

func _start_game(scene_path: String) -> void:
	var audio_manager: AudioManager = Services.audio_manager
	if audio_manager:
		audio_manager.try_play_bgm()
	get_tree().change_scene_to_file(scene_path)

func _on_new_game_pressed() -> void:
	save_manager.delete_save()
	_start_game("res://scenes/main.tscn")

func _on_continue_pressed() -> void:
	_start_game("res://scenes/main.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
