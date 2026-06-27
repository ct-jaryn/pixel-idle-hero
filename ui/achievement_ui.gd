extends BaseSubUI

const ACHIEVEMENT_ICON: Texture2D = preload("res://assets/images/icon_achievement.png")
const CIRCLE_ICON: Texture2D = preload("res://assets/images/icon_circle.png")

@onready var achievement_list: VBoxContainer = %AchievementList
@onready var progress_label: Label = %ProgressLabel

var achievement_manager: AchievementManager = null
var _achievement_cards: Dictionary = {}

func _ready() -> void:
	super._ready()
	if game_manager:
		achievement_manager = game_manager.achievement_manager
		if achievement_manager:
			achievement_manager.achievement_unlocked.connect(_on_achievement_unlocked)

func show_panel() -> void:
	super.show_panel()
	_rebuild_all()

func show_achievements() -> void:
	show_panel()

func hide_achievements() -> void:
	hide_panel()

func _on_back_pressed() -> void:
	_play_ui_click()
	hide_achievements()
	if battle_ui:
		battle_ui.show_battle.call_deferred()

func _rebuild_all() -> void:
	if achievement_manager == null:
		return
	
	progress_label.text = "完成度 %d/%d" % [achievement_manager.get_completed_count(), achievement_manager.get_total_count()]
	
	for child: Node in achievement_list.get_children():
		child.queue_free()
	_achievement_cards.clear()
	
	for ach: AchievementData in achievement_manager.achievements:
		var card: PanelContainer = _build_card(ach)
		achievement_list.add_child(card)
		_achievement_cards[ach] = card

func _build_card(ach: AchievementData) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	_set_card_style(style, ach)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var title_row: HBoxContainer = HBoxContainer.new()
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var icon: TextureRect = TextureRect.new()
	icon.name = "Icon"
	icon.texture = ACHIEVEMENT_ICON if ach.completed else CIRCLE_ICON
	icon.custom_minimum_size = Vector2(20, 20)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var title: Label = Label.new()
	title.name = "TitleLabel"
	title.text = ach.name
	title.add_theme_font_size_override("font_size", 18)
	if ach.completed:
		title.add_theme_color_override("font_color", Color.GOLD)
	
	var type_label: Label = Label.new()
	type_label.name = "TypeLabel"
	type_label.text = ach.get_type_name()
	type_label.add_theme_font_size_override("font_size", 13)
	type_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 1))
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	type_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	title_row.add_child(icon)
	title_row.add_child(title)
	title_row.add_child(type_label)
	
	var desc: Label = Label.new()
	desc.name = "DescLabel"
	desc.text = ach.description
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1))
	
	var reward: Label = Label.new()
	reward.name = "RewardLabel"
	reward.text = ach.get_reward_text()
	reward.add_theme_font_size_override("font_size", 13)
	reward.add_theme_color_override("font_color", Color.LIME_GREEN)
	
	vbox.add_child(title_row)
	vbox.add_child(desc)
	vbox.add_child(reward)
	card.add_child(vbox)
	return card

func _set_card_style(style: StyleBoxFlat, ach: AchievementData) -> void:
	if ach.completed:
		style.bg_color = Color(0.18, 0.28, 0.18, 0.95)
		style.border_color = Color(0.7, 0.65, 0.25, 1)
	else:
		style.bg_color = Color(0.12, 0.12, 0.16, 0.95)
		style.border_color = Color(0.35, 0.32, 0.45, 1)

func _update_card(ach: AchievementData) -> void:
	var card: PanelContainer = _achievement_cards.get(ach) as PanelContainer
	if card == null:
		return
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	_set_card_style(style, ach)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)
	
	var vbox: VBoxContainer = card.get_child(0) as VBoxContainer
	var title_row: HBoxContainer = vbox.get_child(0) as HBoxContainer
	var icon: TextureRect = title_row.get_node("Icon") as TextureRect
	var title: Label = title_row.get_node("TitleLabel") as Label
	
	icon.texture = ACHIEVEMENT_ICON if ach.completed else CIRCLE_ICON
	title.text = ach.name
	if ach.completed:
		title.add_theme_color_override("font_color", Color.GOLD)
	else:
		title.remove_theme_color_override("font_color")

func _on_achievement_unlocked(achievement: AchievementData) -> void:
	if visible:
		_update_card(achievement)
		progress_label.text = "完成度 %d/%d" % [achievement_manager.get_completed_count(), achievement_manager.get_total_count()]
