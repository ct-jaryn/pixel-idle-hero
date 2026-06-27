class_name BaseSubUI
extends CanvasLayer

@export var game_manager: GameManager
@export var battle_ui: CanvasLayer

func _ready() -> void:
	visible = false
	add_to_group("sub_ui")
	if game_manager == null:
		game_manager = Services.game_manager
	## battle_ui 由场景通过 @export NodePath 接线，无需代码兜底查找。
	var back_button: Button = _find_back_button()
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func _find_back_button() -> Button:
	return get_node_or_null("%BackButton") as Button

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()

func show_panel() -> void:
	## 子界面互斥：打开新面板前关闭其他已打开的子界面
	for sub_ui: CanvasLayer in get_tree().get_nodes_in_group("sub_ui"):
		if sub_ui != self and sub_ui.visible and sub_ui.has_method("hide_panel"):
			sub_ui.hide_panel()
	visible = true
	_refresh()
	var focus_target: Control = _find_back_button() as Control
	if focus_target == null:
		focus_target = _find_first_focusable(self)
	if focus_target != null:
		focus_target.grab_focus()

func _find_first_focusable(node: Node) -> Control:
	for child: Node in node.get_children():
		if child is Control and (child as Control).focus_mode != Control.FOCUS_NONE:
			return child as Control
		var found: Control = _find_first_focusable(child)
		if found != null:
			return found
	return null

func hide_panel() -> void:
	visible = false

func close_panel() -> void:
	## 公开方法：关闭面板并返回战斗界面，供 PauseMenu/全局导航调用
	_on_back_pressed()

func _on_back_pressed() -> void:
	_play_ui_click()
	hide_panel()
	if battle_ui:
		battle_ui.show_battle()

func _refresh() -> void:
	pass

func _play_ui_click() -> void:
	EventBus.play_sfx.emit("ui_click")

func _play_ui_hover() -> void:
	EventBus.play_sfx.emit("ui_hover")
