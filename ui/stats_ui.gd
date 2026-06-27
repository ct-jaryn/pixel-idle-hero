extends BaseSubUI

@onready var stats_text: RichTextLabel = %StatsText

func _ready() -> void:
	super._ready()

func show_stats() -> void:
	show_panel()

func hide_stats() -> void:
	hide_panel()

func _on_back_pressed() -> void:
	_play_ui_click()
	hide_stats()
	if battle_ui:
		battle_ui.show_battle.call_deferred()

func _refresh() -> void:
	if game_manager == null or game_manager.player_data == null:
		return
	
	var pd: PlayerData = game_manager.player_data
	var play_time: String = _format_time(pd.play_time_seconds)
	
	stats_text.text = """
[center][b][color=gold]冒险者统计[/color][/b][/center]

[color=#d4b86a]基础属性[/color]
等级：Lv.%d
攻击：%d
防御：%d
生命：%d / %d
攻速：%.2f
暴击：%.1f%%

[color=#d4b86a]战斗记录[/color]
击杀：%d
累计金币：%d
造成伤害：%d
承受伤害：%d
死亡：%d
击败 Boss：%d
最高关卡：%d

[color=#d4b86a]其他[/color]
游戏时间：%s
当前金币：%d
""" % [
		pd.level, pd.attack, pd.defense, pd.hp, pd.max_hp,
		pd.attack_speed, pd.crit_rate * 100.0,
		pd.total_kills, pd.total_gold_earned, pd.total_damage_dealt,
		pd.total_damage_taken, pd.death_count, pd.bosses_defeated,
		pd.highest_stage, play_time, pd.gold
	]

func _format_time(seconds: float) -> String:
	var hours: int = int(seconds) / 3600
	var minutes: int = (int(seconds) % 3600) / 60
	var secs: int = int(seconds) % 60
	return "%02d:%02d:%02d" % [hours, minutes, secs]
