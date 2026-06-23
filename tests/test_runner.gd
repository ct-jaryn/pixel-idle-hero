extends Node

## 核心逻辑 headless 单元测试 Runner
## 运行方式：
## ./Godot_v4.3-stable_win64_console.exe --headless --path . res://tests/test_runner.tscn

var _passed: int = 0
var _failed: int = 0

func _ready() -> void:
	print("=== 开始核心逻辑单元测试 ===")
	
	test_player_data_leveling()
	test_player_data_gold()
	test_player_data_combat()
	test_equipment_manager_basic()
	test_equipment_manager_sell()
	test_enemy_data_stats()
	test_enemy_data_scaling()
	test_boss_mechanics()
	test_skill_manager()
	test_save_round_trip()
	test_reward_manager_gold_single_count()
	
	print("=== 测试结束 ===")
	print("通过：%d，失败：%d" % [_passed, _failed])
	get_tree().quit(_failed > 0)

func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  [PASS] %s" % message)
	else:
		_failed += 1
		push_error("  [FAIL] %s" % message)

func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	_assert(actual == expected, "%s (期望 %s，实际 %s)" % [message, str(expected), str(actual)])

func test_player_data_leveling() -> void:
	print("\n[PlayerData] 升级逻辑")
	var pd: PlayerData = PlayerData.new()
	pd.gain_exp(pd.exp_to_next)
	_assert(pd.level == 2, "升级后等级为 2")
	_assert(pd.exp == 0, "升级后当前经验清零")
	_assert(pd.exp_to_next > 100, "下一级所需经验递增")

func test_player_data_gold() -> void:
	print("\n[PlayerData] 金币逻辑")
	var pd: PlayerData = PlayerData.new()
	pd.add_gold(100)
	_assert_eq(pd.gold, 100, "加金币后余额正确")
	pd.spend_gold(30)
	_assert_eq(pd.gold, 70, "消费后余额正确")
	_assert(not pd.spend_gold(100), "余额不足时消费失败")
	_assert_eq(pd.gold, 70, "消费失败后余额不变")

func test_player_data_combat() -> void:
	print("\n[PlayerData] 战斗数值")
	var pd: PlayerData = PlayerData.new()
	pd.max_hp = 100
	pd.hp = 100
	pd.defense = 5
	var actual: int = pd.take_damage(20)
	_assert_eq(actual, 15, "伤害结算减防正确")
	_assert_eq(pd.hp, 85, "受伤后血量正确")
	pd.heal(10)
	_assert_eq(pd.hp, 95, "治疗后血量正确")
	pd.heal(100)
	_assert_eq(pd.hp, 100, "治疗不超过最大生命")

func test_equipment_manager_basic() -> void:
	print("\n[EquipmentManager] 装备穿戴")
	var em: EquipmentManager = EquipmentManager.new()
	var equip: EquipmentData = EquipmentData.new("测试剑", EquipmentData.Type.WEAPON, EquipmentData.Rarity.COMMON, 1)
	em.add_to_inventory(equip)
	_assert_eq(em.inventory.size(), 1, "装备加入背包")
	_assert(em.equip_item(equip), "穿戴成功")
	_assert_eq(em.inventory.size(), 0, "穿戴后从背包移除")
	_assert(em.get_equipped(EquipmentData.Type.WEAPON) == equip, "已装备部位正确")
	var result: EquipmentManager.UnequipResult = em.unequip_item(EquipmentData.Type.WEAPON)
	_assert_eq(result, EquipmentManager.UnequipResult.SUCCESS, "卸下成功")
	_assert_eq(em.inventory.size(), 1, "卸下后回到背包")

func test_equipment_manager_sell() -> void:
	print("\n[EquipmentManager] 装备出售")
	var em: EquipmentManager = EquipmentManager.new()
	var equip: EquipmentData = EquipmentData.new("测试剑", EquipmentData.Type.WEAPON, EquipmentData.Rarity.COMMON, 1)
	em.add_to_inventory(equip)
	var result: Dictionary = em.sell_item(equip)
	_assert(result.ok, "出售成功")
	_assert(result.price > 0, "出售价格大于 0")
	_assert_eq(em.inventory.size(), 0, "出售后背包清空")
	var fail: Dictionary = em.sell_item(equip)
	_assert(not fail.ok, "出售不存在的装备失败")

func test_enemy_data_stats() -> void:
	print("\n[EnemyData] 属性生成")
	var enemy: EnemyData = EnemyData.new("史莱姆", 1, false)
	_assert(enemy.max_hp > 0, "普通怪最大生命大于 0")
	_assert(enemy.attack > 0, "普通怪攻击大于 0")
	_assert_eq(enemy.is_boss, false, "普通怪不是 Boss")
	
	var boss: EnemyData = EnemyData.new("恶龙", 10, true)
	_assert(boss.max_hp > enemy.max_hp, "Boss 生命高于普通怪")
	_assert(boss.is_boss, "Boss 标记正确")

func test_enemy_data_scaling() -> void:
	print("\n[EnemyData] 属性倍率独立生效")
	## 在等级 11 处 HP/ATK/DEF 倍率各不相同，验证三者分别使用各自常量而非共用 ATK 倍率
	var enemy: EnemyData = EnemyData.new("测试怪", 11, false)
	var hp_mult: float = 1.0 + (enemy.level - 1) * BalanceConfig.ENEMY_HP_MULTIPLIER
	var def_mult: float = 1.0 + (enemy.level - 1) * BalanceConfig.ENEMY_DEF_MULTIPLIER
	_assert_eq(enemy.max_hp, int(BalanceConfig.ENEMY_BASE_HP * hp_mult), "HP 使用 ENEMY_HP_MULTIPLIER")
	_assert_eq(enemy.defense, int((BalanceConfig.ENEMY_BASE_DEF + enemy.level * 0.3) * def_mult), "DEF 使用 ENEMY_DEF_MULTIPLIER")
	## 确认 HP 倍率确实高于 ATK 倍率（否则常量未生效）
	_assert(BalanceConfig.ENEMY_HP_MULTIPLIER > BalanceConfig.ENEMY_ATK_MULTIPLIER, "HP 成长倍率高于 ATK")
	_assert(BalanceConfig.ENEMY_DEF_MULTIPLIER < BalanceConfig.ENEMY_ATK_MULTIPLIER, "DEF 成长倍率低于 ATK")

func test_boss_mechanics() -> void:
	print("\n[BossMechanics] Boss 机制")
	var boss: EnemyData = EnemyData.new("恶龙", 10, true)
	var initial_hp: int = boss.max_hp - 50
	boss.hp = initial_hp
	var mechanics: BossMechanics = BossMechanics.new(boss)
	
	## 6 秒治疗
	mechanics.update(BalanceConfig.BOSS_HEAL_INTERVAL + 0.1)
	_assert(boss.hp > initial_hp, "Boss 治疗后血量增加")
	_assert(boss.hp <= boss.max_hp, "Boss 治疗后血量不超过上限")
	
	## 推进到狂暴触发（前面已推进 6.1 秒，再推进约 6 秒即可达到 12 秒冷却）
	for i: int in range(6):
		mechanics.update(1.0)
	_assert(mechanics.is_berserk, "Boss 进入狂暴")
	_assert(boss.attack_speed > mechanics.base_attack_speed, "狂暴时攻速提升")
	
	## 4 秒后结束狂暴
	mechanics.update(BalanceConfig.BOSS_BERSERK_DURATION + 0.1)
	_assert(not mechanics.is_berserk, "狂暴结束")

func test_skill_manager() -> void:
	print("\n[SkillManager] 技能逻辑")
	var sm: SkillManager = SkillManager.new()
	## 直接调用 _ready 中的初始化，因为 new() 不会触发 _ready
	sm._init_default_skills()
	add_child(sm)
	
	var pd: PlayerData = PlayerData.new()
	pd.max_hp = 100
	pd.hp = 50
	pd.attack = 20
	sm.player_data = pd
	
	var bm: BattleManager = BattleManager.new()
	add_child(bm)
	bm.player_data = pd
	bm.start_battle(EnemyData.new("史莱姆", 1, false))
	sm.battle_manager = bm
	
	## 能量相关
	sm.add_energy(100)
	_assert_eq(sm.energy, 100, "能量加满")
	
	var heal_skill: SkillData = sm.skills[SkillData.Type.HEAL]
	_assert(sm.can_cast(heal_skill), "有能量时可施放治疗")
	
	sm.cast_skill(heal_skill)
	_assert(pd.hp > 50, "治疗生效")
	_assert(sm.cooldowns.has(SkillData.Type.HEAL), "治疗进入冷却")
	_assert(not sm.can_cast(heal_skill), "冷却中不可施放")
	
	## 重击需要敌人
	var heavy_skill: SkillData = sm.skills[SkillData.Type.HEAVY_HIT]
	_assert(sm.cast_skill(heavy_skill), "有敌人时可施放重击")
	
	## 狂暴注入攻速倍率
	var berserk_skill: SkillData = sm.skills[SkillData.Type.BERSERK]
	sm.energy = 100
	sm.cast_skill(berserk_skill)
	_assert_eq(pd.attack_speed_multiplier, BalanceConfig.SKILL_BERSERK_MULTIPLIER, "狂暴倍率写入 PlayerData")
	
	## 模拟时间结束狂暴
	sm._process(BalanceConfig.SKILL_BERSERK_DURATION + 0.1)
	_assert_eq(pd.attack_speed_multiplier, 1.0, "狂暴结束后倍率恢复")
	
	sm.queue_free()
	bm.queue_free()

func test_save_round_trip() -> void:
	print("\n[SaveManager] 存档序列化往返")
	var pd: PlayerData = PlayerData.new()
	pd.add_gold(1234)
	pd.gain_exp(pd.exp_to_next)
	pd.bonus_attack = 5
	pd.recalc_stats()
	
	var em: EquipmentManager = EquipmentManager.new()
	var equip: EquipmentData = EquipmentData.new("测试剑", EquipmentData.Type.WEAPON, EquipmentData.Rarity.RARE, 3)
	em.add_to_inventory(equip)
	
	var sm: SaveManager = SaveManager.new()
	var save_path: String = sm.SAVE_PATH
	var backup_path: String = save_path + ".test_backup"
	
	## 备份现有存档（如有），避免污染
	var dir: DirAccess = DirAccess.open("user://")
	if dir != null and FileAccess.file_exists(save_path):
		dir.copy(save_path, backup_path)
		dir.remove(save_path)
	
	var save_ok: bool = sm.save_game(pd, em, 5, null, null, null)
	_assert(save_ok, "存档写入成功")
	
	var pd2: PlayerData = PlayerData.new()
	var em2: EquipmentManager = EquipmentManager.new()
	var gm: GameManager = GameManager.new()
	var load_ok: bool = sm.load_game(pd2, em2, gm, null, null)
	_assert(load_ok, "存档读取成功")
	_assert_eq(pd2.gold, 1234, "金币往返正确")
	_assert_eq(pd2.level, 2, "等级往返正确")
	_assert_eq(em2.inventory.size(), 1, "背包装备往返正确")
	var loaded: EquipmentData = em2.inventory[0]
	_assert_eq(loaded.equip_name, "测试剑", "装备名称往返正确")
	_assert_eq(loaded.rarity, EquipmentData.Rarity.RARE, "装备稀有度往返正确")
	
	## 清理并恢复备份
	if dir != null:
		if FileAccess.file_exists(save_path):
			dir.remove(save_path)
		if FileAccess.file_exists(save_path + ".tmp"):
			dir.remove(save_path + ".tmp")
		if FileAccess.file_exists(save_path + ".bak"):
			dir.remove(save_path + ".bak")
		if FileAccess.file_exists(backup_path):
			dir.copy(backup_path, save_path)
			dir.remove(backup_path)

func test_reward_manager_gold_single_count() -> void:
	print("\n[RewardManager] 击败敌人金币只累计一次")
	var pd: PlayerData = PlayerData.new()
	var stage: StageManager = StageManager.new()
	stage.current_enemy_level = 1
	var rm: RewardManager = RewardManager.new()
	rm.player_data = pd
	rm.stage_manager = stage
	rm.equipment_manager = null
	rm.shop_manager = null

	var enemy: EnemyData = EnemyData.new("史莱姆", 1, false)
	var gold_before: int = pd.total_gold_earned
	rm._on_enemy_defeated(enemy)
	## add_gold 内部已累加 total_gold_earned，reward_manager 不得再次累加，否则翻倍
	_assert_eq(pd.total_gold_earned, gold_before + enemy.gold_reward, "累计金币只增加一次掉落金币")
