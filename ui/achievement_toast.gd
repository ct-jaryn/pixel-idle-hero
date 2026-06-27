extends CanvasLayer

const ACHIEVEMENT_ICON: Texture2D = preload("res://assets/images/icon_achievement.png")

@onready var panel: PanelContainer = %PanelContainer
@onready var title_label: Label = %TitleLabel
@onready var name_label: Label = %NameLabel
@onready var reward_label: Label = %RewardLabel

const SHOW_Y: float = 80.0
const HIDE_Y: float = -200.0
const ANIM_DURATION: float = 0.4
const DISPLAY_DURATION: float = 2.5

var _tween: Tween = null
var _queue: Array[AchievementData] = []
var _is_showing: bool = false

func _ready() -> void:
	visible = false
	panel.position = Vector2(panel.position.x, HIDE_Y)
	var icon: TextureRect = TextureRect.new()
	icon.texture = ACHIEVEMENT_ICON
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	title_label.get_parent().add_child(icon)
	title_label.get_parent().move_child(icon, title_label.get_index())

func show_achievement(achievement: AchievementData) -> void:
	_queue.append(achievement)
	if not _is_showing:
		_process_queue()

func _process_queue() -> void:
	if _queue.is_empty():
		_is_showing = false
		visible = false
		return
	_is_showing = true
	var achievement: AchievementData = _queue.pop_front()
	title_label.text = "成就解锁"
	name_label.text = achievement.name
	reward_label.text = achievement.get_reward_text()

	if _tween and _tween.is_valid():
		_tween.kill()

	visible = true
	panel.modulate = Color.WHITE
	panel.position = Vector2(panel.position.x, HIDE_Y)

	_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(panel, "position:y", SHOW_Y, ANIM_DURATION)
	_tween.tween_interval(DISPLAY_DURATION)
	_tween.tween_property(panel, "modulate", Color(1, 1, 1, 0), 0.3)
	_tween.tween_callback(_process_queue)

func _hide() -> void:
	visible = false
	panel.position = Vector2(panel.position.x, HIDE_Y)
