extends CanvasLayer

@export var game_manager: GameManager

@onready var resume_button: Button = %ResumeButton
@onready var title_button: Button = %TitleButton
@onready var reset_button: Button = %ResetButton
@onready var quit_button: Button = %QuitButton
@onready var bgm_check: CheckBox = %BGMCheck
@onready var sfx_check: CheckBox = %SFXCheck

func _ready() -> void:
	visible = false
	## 暂停菜单需要在树暂停时继续处理输入和 UI 交互
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	if OS.has_feature("web"):
		quit_button.visible = false

	resume_button.pressed.connect(_on_resume_pressed)
	title_button.pressed.connect(_on_title_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	bgm_check.toggled.connect(_on_bgm_toggled)
	sfx_check.toggled.connect(_on_sfx_toggled)

	for btn: Button in [resume_button, title_button, reset_button, quit_button]:
		btn.mouse_entered.connect(func() -> void: EventBus.play_sfx.emit("ui_hover"))
		btn.focus_entered.connect(func() -> void: EventBus.play_sfx.emit("ui_hover"))

	var audio: AudioManager = Services.audio_manager
	if audio:
		bgm_check.button_pressed = audio.bgm_enabled
		sfx_check.button_pressed = audio.sfx_enabled

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("toggle_pause"):
		## 子界面打开时，先关闭子界面而不是弹出暂停菜单
		if not visible:
			for sub_ui: CanvasLayer in get_tree().get_nodes_in_group("sub_ui"):
				if sub_ui.visible:
					get_viewport().set_input_as_handled()
					if sub_ui.has_method("close_panel"):
						sub_ui.close_panel()
					return
		if visible:
			_resume()
		else:
			_pause()

func _pause() -> void:
	visible = true
	get_tree().paused = true
	resume_button.grab_focus()
	EventBus.play_sfx.emit("ui_click")

func _resume() -> void:
	visible = false
	get_tree().paused = false

func _on_resume_pressed() -> void:
	EventBus.play_sfx.emit("ui_click")
	_resume()

func _on_title_pressed() -> void:
	EventBus.play_sfx.emit("ui_click")
	_resume()
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _on_reset_pressed() -> void:
	EventBus.play_sfx.emit("ui_click")
	var save_manager: SaveManager = SaveManager.new()
	save_manager.delete_save()
	_resume()
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	EventBus.play_sfx.emit("ui_click")
	get_tree().quit()

func _on_bgm_toggled(enabled: bool) -> void:
	var audio: AudioManager = Services.audio_manager
	if audio:
		audio.set_bgm_enabled(enabled)

func _on_sfx_toggled(enabled: bool) -> void:
	var audio: AudioManager = Services.audio_manager
	if audio:
		audio.set_sfx_enabled(enabled)
