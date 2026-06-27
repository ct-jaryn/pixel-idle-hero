extends BaseSubUI

const CHECK_ICON: Texture2D = preload("res://assets/images/icon_check.png")

@onready var quest_list: VBoxContainer = %QuestList
@onready var refresh_button: Button = %RefreshButton
@onready var message_label: Label = %MessageLabel

var quest_manager: QuestManager = null
var _quest_cards: Dictionary = {}

func _ready() -> void:
	super._ready()
	refresh_button.pressed.connect(_on_refresh_pressed)
	if game_manager:
		quest_manager = game_manager.quest_manager
	EventBus.daily_quests_refreshed.connect(_rebuild_all)
	EventBus.quest_updated.connect(_on_quest_updated)

func show_quests() -> void:
	show_panel()

func hide_quests() -> void:
	hide_panel()

func _on_back_pressed() -> void:
	_play_ui_click()
	hide_quests()
	if battle_ui:
		battle_ui.show_battle.call_deferred()

func show_panel() -> void:
	super.show_panel()
	_rebuild_all()

func _rebuild_all() -> void:
	_clear_list()
	_quest_cards.clear()
	if quest_manager == null:
		return
	
	_update_refresh_button()
	
	for quest: QuestData in quest_manager.quests:
		var card: PanelContainer = _build_card(quest)
		quest_list.add_child(card)
		_quest_cards[quest] = card

func _build_card(quest: QuestData) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	_set_card_style(style, quest)
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
	
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 12)
	
	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var title_row: HBoxContainer = HBoxContainer.new()
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var title: Label = Label.new()
	title.name = "TitleLabel"
	title.text = quest.title
	title.add_theme_font_size_override("font_size", 18)
	
	var progress: Label = Label.new()
	progress.name = "ProgressLabel"
	progress.text = quest.get_progress_text()
	progress.add_theme_font_size_override("font_size", 14)
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	title_row.add_child(title)
	title_row.add_child(progress)
	
	var desc: Label = Label.new()
	desc.name = "DescLabel"
	desc.text = quest.description
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1))
	
	var reward: Label = Label.new()
	reward.name = "RewardLabel"
	reward.text = "奖励：%s" % quest.get_reward_text()
	reward.add_theme_font_size_override("font_size", 13)
	reward.add_theme_color_override("font_color", Color.LIME_GREEN)
	
	var progress_bar: ProgressBar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.value = quest.get_progress_ratio() * 100.0
	progress_bar.max_value = 100.0
	progress_bar.size_flags_vertical = 4
	_set_quest_bar_colors(progress_bar)
	
	info.add_child(title_row)
	info.add_child(desc)
	info.add_child(progress_bar)
	info.add_child(reward)
	
	var action: Control = _create_action_control(quest)
	action.name = "ActionControl"
	
	hbox.add_child(info)
	hbox.add_child(action)
	card.add_child(hbox)
	return card

func _set_card_style(style: StyleBoxFlat, quest: QuestData) -> void:
	if quest.claimed:
		style.bg_color = Color(0.15, 0.25, 0.15, 0.95)
		style.border_color = Color(0.4, 0.7, 0.4, 1)
	elif quest.completed:
		style.bg_color = Color(0.25, 0.2, 0.1, 0.95)
		style.border_color = Color(1.0, 0.75, 0.2, 1)
	else:
		style.bg_color = Color(0.12, 0.12, 0.16, 0.95)
		style.border_color = Color(0.35, 0.32, 0.45, 1)

func _update_card(quest: QuestData) -> void:
	var card: PanelContainer = _quest_cards.get(quest) as PanelContainer
	if card == null:
		return
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	_set_card_style(style, quest)
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
	
	var hbox: HBoxContainer = card.get_child(0) as HBoxContainer
	var info: VBoxContainer = hbox.get_child(0) as VBoxContainer
	var title_row: HBoxContainer = info.get_child(0) as HBoxContainer
	var title: Label = title_row.get_node("TitleLabel") as Label
	var progress_label: Label = title_row.get_node("ProgressLabel") as Label
	var reward: Label = info.get_node("RewardLabel") as Label
	var progress_bar: ProgressBar = info.get_node("ProgressBar") as ProgressBar
	var action: Control = hbox.get_node("ActionControl") as Control
	
	title.text = quest.title
	if quest.completed:
		title.add_theme_color_override("font_color", Color.GOLD)
	else:
		title.remove_theme_color_override("font_color")
	progress_label.text = quest.get_progress_text()
	reward.text = "奖励：%s" % quest.get_reward_text()
	progress_bar.value = quest.get_progress_ratio() * 100.0
	
	## 替换 action 区域
	action.queue_free()
	var new_action: Control = _create_action_control(quest)
	new_action.name = "ActionControl"
	hbox.add_child(new_action)
	hbox.move_child(new_action, 1)

func _set_quest_bar_colors(bar: ProgressBar) -> void:
	var fg: StyleBoxFlat = bar.get_theme_stylebox("fill").duplicate()
	var bg: StyleBoxFlat = bar.get_theme_stylebox("background").duplicate()
	fg.bg_color = Color(0.3, 0.85, 0.35, 1)
	bg.bg_color = Color(0.1, 0.15, 0.1, 1)
	bar.add_theme_stylebox_override("fill", fg)
	bar.add_theme_stylebox_override("background", bg)

func _create_action_control(quest: QuestData) -> Control:
	if quest.claimed:
		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 4)
		var icon: TextureRect = TextureRect.new()
		icon.texture = CHECK_ICON
		icon.custom_minimum_size = Vector2(18, 18)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var label: Label = Label.new()
		label.text = "已领取"
		label.add_theme_color_override("font_color", Color.GREEN)
		hbox.add_child(icon)
		hbox.add_child(label)
		return hbox
	
	if quest.completed:
		var btn: Button = Button.new()
		btn.text = "领取"
		btn.custom_minimum_size = Vector2(72, 44)
		btn.pressed.connect(_on_claim_pressed.bind(quest))
		btn.mouse_entered.connect(_play_ui_hover)
		return btn
	
	var label: Label = Label.new()
	label.text = "进行中"
	label.add_theme_color_override("font_color", Color.GRAY)
	return label

func _clear_list() -> void:
	for child: Node in quest_list.get_children():
		child.queue_free()

func _on_quest_updated(quest: QuestData) -> void:
	if visible:
		_update_card(quest)
		_update_refresh_button()

func _on_refresh_pressed() -> void:
	_play_ui_click()
	if quest_manager == null:
		return
	if quest_manager.try_manual_refresh():
		_rebuild_all()
	else:
		_show_message("刷新失败")

func _on_claim_pressed(quest: QuestData) -> void:
	_play_ui_click()
	if quest_manager == null:
		return
	if quest_manager.claim_reward(quest):
		_show_message("领取成功！")
		_update_card(quest)

func _update_refresh_button() -> void:
	if quest_manager == null:
		return
	if quest_manager.free_refresh_used:
		refresh_button.text = "刷新 (%d 金币)" % QuestManager.REFRESH_COST
	else:
		refresh_button.text = "免费刷新"

func _show_message(text: String) -> void:
	message_label.text = text
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(message_label):
		message_label.text = ""
