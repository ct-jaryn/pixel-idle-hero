class_name GameManager
extends Node

## 组合根：负责创建各子系统管理器、注册到 Services、桥接 PlayerData 领域信号到
## EventBus，以及加载存档与启动首场战斗。
##
## 跨管理器依赖不再在此手动接线——各管理器通过 Services 自行解析协作者。

@onready var background: TextureRect = %Background

var player_data: PlayerData
var battle_manager: BattleManager
var equipment_manager: EquipmentManager
var skill_manager: SkillManager
var shop_manager: ShopManager
var achievement_manager: AchievementManager
var stage_manager: StageManager
var reward_manager: RewardManager
var quest_manager: QuestManager

var save_manager: SaveManager = null
const SAVE_INTERVAL: float = BalanceConfig.SAVE_INTERVAL
var save_timer: float = 0.0

func _ready() -> void:
	_init_subsystems()
	_connect_events()
	_load_save()

	if stage_manager:
		stage_manager.spawn_normal_enemy()

func _init_subsystems() -> void:
	## PlayerData 是 Resource，无 _ready，需在此先注册，供后续管理器在 _ready 中解析。
	player_data = PlayerData.new()
	Services.player_data = player_data
	Services.game_manager = self

	## 创建顺序保证：被依赖的管理器先于依赖方注册（battle 先于 skill/stage/reward/quest）。
	battle_manager = _ensure(BattleManager)
	equipment_manager = _ensure(EquipmentManager)
	skill_manager = _ensure(SkillManager)
	shop_manager = _ensure(ShopManager)
	stage_manager = _ensure(StageManager)
	stage_manager.background = background
	reward_manager = _ensure(RewardManager)
	achievement_manager = _ensure(AchievementManager)
	quest_manager = _ensure(QuestManager)

	save_manager = SaveManager.new()
	Services.save_manager = save_manager

func _ensure(script_class: GDScript) -> Node:
	var instance: Node = script_class.new()
	add_child(instance)
	return instance

func _connect_events() -> void:
	## 桥接 PlayerData 领域信号到全局 EventBus，供 UI/任务等跨子系统消费。
	if player_data:
		player_data.leveled_up.connect(_on_player_leveled_up)
		player_data.stats_changed.connect(_on_player_stats_changed)
		player_data.gold_changed.connect(_on_player_gold_changed)
	## 战斗死亡由 BattleManager 直发，此处直接处理复活逻辑。
	if battle_manager:
		battle_manager.player_died.connect(_on_player_died)
	## 装备变动 → 重算玩家属性
	if equipment_manager:
		equipment_manager.equipment_changed.connect(_on_equipment_changed)
	## Boss 机制事件仅用于日志反馈
	EventBus.boss_healed.connect(_on_boss_healed)
	EventBus.boss_berserk.connect(_on_boss_berserk)

func _on_player_leveled_up(new_level: int) -> void:
	EventBus.player_leveled_up.emit(new_level)
	EventBus.play_sfx.emit("level_up")

func _on_player_stats_changed() -> void:
	EventBus.stats_changed.emit()

func _on_player_gold_changed(amount: int) -> void:
	EventBus.gold_changed.emit(amount)

func _load_save() -> void:
	if save_manager == null:
		return
	if save_manager.has_save():
		if save_manager.load_game(player_data, equipment_manager, stage_manager, achievement_manager, quest_manager, skill_manager, shop_manager):
			EventBus.message_logged.emit("已加载存档")
			reward_manager.apply_offline_rewards(save_manager.get_last_save_time())
		else:
			EventBus.message_logged.emit("存档加载失败，开始新游戏")

func _process(delta: float) -> void:
	save_timer += delta
	if save_timer >= SAVE_INTERVAL:
		save_timer = 0.0
		_save_game()

	if player_data:
		player_data.play_time_seconds += delta

func _save_game() -> void:
	if save_manager == null or player_data == null or equipment_manager == null or stage_manager == null:
		return
	save_manager.save_game(player_data, equipment_manager, stage_manager, achievement_manager, quest_manager, skill_manager, shop_manager)

func challenge_boss() -> bool:
	if stage_manager:
		return stage_manager.challenge_boss()
	return false

func _on_equipment_changed() -> void:
	var bonuses: Dictionary = equipment_manager.get_equipment_bonuses()
	player_data.set_equipment_bonuses(bonuses)

func _on_player_died() -> void:
	player_data.death_count += 1
	EventBus.message_logged.emit("勇者倒下了！正在复活...")
	await get_tree().create_timer(BalanceConfig.REVIVE_DELAY).timeout
	if not is_instance_valid(self) or player_data == null or stage_manager == null:
		return
	player_data.heal(player_data.max_hp)
	if battle_manager:
		battle_manager.player_attack_timer = 0.0
		battle_manager.enemy_attack_timer = 0.0
	stage_manager.spawn_normal_enemy()
	var player_node = get_tree().get_first_node_in_group("player") as Node2D
	if player_node and player_node.has_method("revive"):
		player_node.revive()

func _on_boss_healed(amount: int) -> void:
	EventBus.message_logged.emit("Boss 恢复了 %d 点生命！" % amount)

func _on_boss_berserk(active: bool) -> void:
	if active:
		EventBus.message_logged.emit("Boss 进入狂暴状态！攻速翻倍！")
	else:
		EventBus.message_logged.emit("Boss 狂暴结束")
