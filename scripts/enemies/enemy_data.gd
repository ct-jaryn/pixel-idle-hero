class_name EnemyData
extends Resource

## 敌人基础属性
var name: String = "Slime"
var level: int = 1
var max_hp: int = 50
var hp: int = 50
var attack: int = 5
var defense: int = 2
var attack_speed: float = 0.8
var exp_reward: int = 20
var gold_reward: int = 10
var is_boss: bool = false

## 外观
var color: Color = Color.GREEN_YELLOW
var size_scale: float = 1.0

func _init(p_name: String, p_level: int, p_is_boss: bool = false) -> void:
	name = p_name
	level = p_level
	is_boss = p_is_boss
	generate_stats()

func generate_stats() -> void:
	## 各属性按独立倍率成长：HP 最快、ATK 居中、DEF 最慢，避免后期沦为纯数值堆叠
	var hp_multiplier: float = 1.0 + (level - 1) * BalanceConfig.ENEMY_HP_MULTIPLIER
	var atk_multiplier: float = 1.0 + (level - 1) * BalanceConfig.ENEMY_ATK_MULTIPLIER
	var def_multiplier: float = 1.0 + (level - 1) * BalanceConfig.ENEMY_DEF_MULTIPLIER
	## 经验/金币沿用攻击倍率（无独立常量），保证产出与战力同步增长
	var reward_multiplier: float = atk_multiplier
	var boss_hp_multiplier: float = BalanceConfig.BOSS_HP_MULTIPLIER if is_boss else 1.0
	var boss_atk_multiplier: float = BalanceConfig.BOSS_ATK_MULTIPLIER if is_boss else 1.0
	var boss_def_multiplier: float = BalanceConfig.BOSS_DEF_MULTIPLIER if is_boss else 1.0
	var boss_exp_multiplier: float = BalanceConfig.BOSS_EXP_MULTIPLIER if is_boss else 1.0
	var boss_gold_multiplier: float = BalanceConfig.BOSS_GOLD_MULTIPLIER if is_boss else 1.0

	max_hp = int(BalanceConfig.ENEMY_BASE_HP * hp_multiplier * boss_hp_multiplier)
	hp = max_hp
	attack = int((BalanceConfig.ENEMY_BASE_ATK + level * 0.8) * atk_multiplier * boss_atk_multiplier)
	defense = int((BalanceConfig.ENEMY_BASE_DEF + level * 0.3) * def_multiplier * boss_def_multiplier)
	attack_speed = min(BalanceConfig.ENEMY_ATK_SPEED_CAP, BalanceConfig.ENEMY_BASE_ATK_SPEED * (1.0 + level * BalanceConfig.ENEMY_ATK_SPEED_LEVEL_GROWTH))

	exp_reward = int(BalanceConfig.ENEMY_BASE_EXP * reward_multiplier * boss_exp_multiplier)
	gold_reward = int(BalanceConfig.ENEMY_BASE_GOLD * reward_multiplier * boss_gold_multiplier)

	if is_boss:
		color = Color.CRIMSON
		size_scale = BalanceConfig.ENEMY_SIZE_SCALE_MAX
	else:
		## 普通怪随等级变色
		var hue: float = fmod(level * 0.08, 1.0)
		color = Color.from_hsv(hue, 0.7, 0.9)
		size_scale = clamp(BalanceConfig.ENEMY_SIZE_SCALE_MIN + (level - 1) * 0.02, BalanceConfig.ENEMY_SIZE_SCALE_MIN, BalanceConfig.ENEMY_SIZE_SCALE_MAX)

func take_damage(damage: int) -> int:
	var actual: int = max(1, damage - defense)
	hp = max(0, hp - actual)
	return actual

func is_alive() -> bool:
	return hp > 0

func heal(amount: int) -> void:
	hp = min(max_hp, hp + amount)

func get_attack_damage() -> Dictionary:
	var is_crit: bool = is_boss and randf() < BalanceConfig.BOSS_CRIT_CHANCE
	var damage: int = attack
	if is_crit:
		damage = int(damage * BalanceConfig.BOSS_CRIT_DAMAGE)
	return {"damage": damage, "is_crit": is_crit}

func get_reward_text() -> String:
	return "EXP +%d  Gold +%d" % [exp_reward, gold_reward]
