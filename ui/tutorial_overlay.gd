extends CanvasLayer

@export var steps: Array[Dictionary] = []
@export var current_step: int = 0

@onready var panel: Panel = %Panel
@onready var label: RichTextLabel = %RichTextLabel
@onready var next_button: Button = %NextButton
@onready var skip_button: Button = %SkipButton
@onready var highlight: ColorRect = %Highlight

signal tutorial_finished

func _ready() -> void:
	visible = false
	next_button.pressed.connect(_next_step)
	skip_button.pressed.connect(_finish)

func start(p_steps: Array[Dictionary]) -> void:
	steps = p_steps
	current_step = 0
	visible = true
	_show_step()

func _show_step() -> void:
	if current_step >= steps.size():
		_finish()
		return
	var step: Dictionary = steps[current_step]
	label.text = step.get("text", "")
	
	var target_path: String = step.get("target", "")
	var target: Control = null
	if target_path != "":
		## TutorialOverlay 被添加到 BattleUI 下，目标节点在 BattleUI 内部，所以从父节点查找
		if get_parent() != null:
			target = get_parent().get_node_or_null(target_path) as Control
		if target == null:
			target = get_node_or_null(target_path) as Control
	if target:
		highlight.visible = true
		var rect: Rect2 = target.get_global_rect()
		highlight.position = rect.position - Vector2(4, 4)
		highlight.size = rect.size + Vector2(8, 8)
	else:
		highlight.visible = false
	next_button.text = "下一步" if current_step < steps.size() - 1 else "开始冒险"

func _next_step() -> void:
	current_step += 1
	_show_step()

func _finish() -> void:
	visible = false
	tutorial_finished.emit()
	queue_free()
