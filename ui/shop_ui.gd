extends BaseSubUI

const GOLD_ICON: Texture2D = preload("res://assets/images/icon_gold.png")

@onready var gold_label: Label = %GoldLabel
@onready var item_list: VBoxContainer = %ItemList
@onready var message_label: Label = %MessageLabel

const ITEM_IDS: PackedStringArray = ["health_potion", "attack_boost", "defense_boost", "exp_potion", "equipment_box"]

func _ready() -> void:
	super._ready()
	if game_manager and game_manager.player_data:
		game_manager.player_data.stats_changed.connect(_update_gold)
	if game_manager and game_manager.shop_manager:
		game_manager.shop_manager.purchase_failed.connect(_show_message)
		game_manager.shop_manager.item_purchased.connect(_on_purchased)
	_setup_gold_icon()
	_refresh()

func show_shop() -> void:
	show_panel()

func hide_shop() -> void:
	hide_panel()

func _on_back_pressed() -> void:
	_play_ui_click()
	hide_shop()
	if battle_ui:
		battle_ui.show_battle.call_deferred()

func _refresh() -> void:
	_update_gold()
	_clear_items()
	if game_manager == null or game_manager.shop_manager == null:
		return
	
	for id: String in ITEM_IDS:
		var item: Dictionary = game_manager.shop_manager.get_item(id)
		if item.is_empty():
			continue
		
		var card: PanelContainer = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var row: HBoxContainer = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 12)
		
		var icon: TextureRect = TextureRect.new()
		icon.custom_minimum_size = Vector2(56, 56)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = load(item.icon)
		row.add_child(icon)
		
		var info: VBoxContainer = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var name_label: Label = Label.new()
		name_label.text = "%s  -  %d 金币" % [item.name, item.price]
		name_label.add_theme_font_size_override("font_size", 18)
		
		var desc_label: Label = Label.new()
		desc_label.text = item.desc
		desc_label.add_theme_font_size_override("font_size", 14)
		desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
		
		info.add_child(name_label)
		info.add_child(desc_label)
		row.add_child(info)
		
		var buy_button: Button = Button.new()
		buy_button.text = "购买"
		buy_button.custom_minimum_size = Vector2(72, 44)
		buy_button.pressed.connect(_on_buy_pressed.bind(id))
		buy_button.mouse_entered.connect(_play_ui_hover)
		row.add_child(buy_button)
		
		card.add_child(row)
		item_list.add_child(card)

func _clear_items() -> void:
	for child: Node in item_list.get_children():
		child.queue_free()

func _on_buy_pressed(id: String) -> void:
	_play_ui_click()
	if game_manager and game_manager.shop_manager:
		if game_manager.shop_manager.purchase(id):
			_show_message("购买成功！")
			_update_gold()

func _on_purchased(_item_id: String, _price: int) -> void:
	_refresh()

func _setup_gold_icon() -> void:
	var icon: TextureRect = TextureRect.new()
	icon.texture = GOLD_ICON
	icon.custom_minimum_size = Vector2(20, 20)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gold_label.get_parent().add_child(icon)
	gold_label.get_parent().move_child(icon, gold_label.get_index())

func _update_gold() -> void:
	if not visible:
		return
	if game_manager and game_manager.player_data:
		gold_label.text = "%d" % game_manager.player_data.gold

func _show_message(text: String) -> void:
	message_label.text = text
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(message_label):
		message_label.text = ""
