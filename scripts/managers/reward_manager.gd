class_name RewardManager
extends Node

@export var player_data: PlayerData
@export var equipment_manager: EquipmentManager
@export var shop_manager: ShopManager
@export var stage_manager: StageManager

const OFFLINE_REWARD_RATE_GOLD: float = BalanceConfig.OFFLINE_REWARD_RATE_GOLD
const OFFLINE_REWARD_RATE_EXP: float = BalanceConfig.OFFLINE_REWARD_RATE_EXP
const MAX_OFFLINE_SECONDS: float = BalanceConfig.OFFLINE_MAX_HOURS * 3600.0

func _ready() -> void:
	add_to_group("reward_manager")
	EventBus.enemy_defeated.connect(_on_enemy_defeated)

func _on_enemy_defeated(enemy: EnemyData) -> void:
	if player_data == null or stage_manager == null:
		return

	var exp_reward: int = int(enemy.exp_reward * (1.0 + player_data.equip_exp_percent / 100.0))
	exp_reward = _apply_exp_bonus(exp_reward)
	var gold_reward: int = int(enemy.gold_reward * (1.0 + player_data.equip_gold_percent / 100.0))

	player_data.gain_exp(exp_reward)
	player_data.add_gold(gold_reward)
	player_data.total_kills += 1
	## total_gold_earned 已在 add_gold 内累加，此处不可重复计入，否则统计与离线收益基线翻倍

	if enemy.is_boss:
		player_data.bosses_defeated += 1

	EventBus.energy_gained.emit(10 if enemy.is_boss else 3)

	EventBus.play_sfx.emit("coin")
	EventBus.message_logged.emit("击败了 %s！EXP +%d  Gold +%d" % [enemy.name, exp_reward, gold_reward])

	if equipment_manager == null:
		return
	if equipment_manager.has_drop_chance(enemy.is_boss):
		var drop: EquipmentData = equipment_manager.generate_drop(enemy.level, enemy.is_boss)
		if equipment_manager.add_to_inventory(drop):
			EventBus.equipment_dropped.emit(drop)
			EventBus.message_logged.emit("掉落：%s" % drop.get_display_name())
		else:
			EventBus.message_logged.emit("背包已满，掉落丢失了！")

func apply_offline_rewards(last_save_time: int) -> void:
	if last_save_time <= 0 or player_data == null:
		return

	var now: int = Time.get_unix_time_from_system()
	var elapsed: float = min(now - last_save_time, MAX_OFFLINE_SECONDS)
	if elapsed < 60.0:
		return

	## 新手保底：基于等级给基础离线收益，避免 total_gold_earned=0 时收益为 1
	var hourly_gold: float = max(float(player_data.level) * 10.0, float(player_data.total_gold_earned) * OFFLINE_REWARD_RATE_GOLD)
	var hourly_exp: float = max(float(player_data.level) * 5.0, float(player_data.exp_to_next) * OFFLINE_REWARD_RATE_EXP)
	## 离线收益上限：避免后期经济通胀
	var stage: int = stage_manager.current_enemy_level if stage_manager else player_data.level
	var max_hourly_gold: float = float(stage) * BalanceConfig.OFFLINE_GOLD_CAP_PER_STAGE
	var max_hourly_exp: float = float(player_data.exp_to_next) * BalanceConfig.OFFLINE_EXP_CAP_FACTOR
	hourly_gold = min(hourly_gold, max_hourly_gold)
	hourly_exp = min(hourly_exp, max_hourly_exp)
	var hours: float = elapsed / 3600.0
	var gold_reward: int = max(1, int(hourly_gold * hours))
	var exp_reward: int = max(1, int(hourly_exp * hours))

	player_data.add_gold(gold_reward)
	player_data.gain_exp(exp_reward)
	EventBus.message_logged.emit("离线 %s，获得 %d 金币和 %d 经验" % [_format_time(elapsed), gold_reward, exp_reward])

func _apply_exp_bonus(exp: int) -> int:
	## 经验药水由 ShopManager 管理
	if shop_manager == null:
		return exp
	if shop_manager.has_method("apply_exp_bonus"):
		return shop_manager.apply_exp_bonus(exp)
	return exp

func _format_time(seconds: float) -> String:
	var hours: int = int(seconds) / 3600
	var minutes: int = (int(seconds) % 3600) / 60
	if hours > 0:
		return "%d 小时 %d 分钟" % [hours, minutes]
	return "%d 分钟" % minutes
