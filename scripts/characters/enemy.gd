extends Node2D

@export var battle_manager: BattleManager

@onready var body: AnimatedSprite2D = $Body
@onready var shadow: Polygon2D = $Shadow
@onready var hit_flash: Timer = $HitFlashTimer
@onready var hp_bar: ProgressBar = $HPBar

var current_enemy: EnemyData = null
var _death_tween: Tween = null

static var _sprite_frames_cache: Dictionary = {}

const ANIM_PATHS: Dictionary = {
	"史莱姆": "res://assets/images/animations/monsters/slime_idle.png",
	"哥布林": "res://assets/images/animations/monsters/goblin_idle.png",
	"蝙蝠": "res://assets/images/animations/monsters/bat_idle.png",
	"骷髅兵": "res://assets/images/animations/monsters/skeleton_idle.png",
	"恶龙": "res://assets/images/animations/monsters/dragon_boss_idle.png",
}

const FALLBACK_NAMES: PackedStringArray = ["史莱姆", "哥布林", "蝙蝠", "骷髅兵"]



func _ready() -> void:
	add_to_group("enemy")
	if battle_manager == null:
		battle_manager = get_tree().get_first_node_in_group("battle_manager") as BattleManager
	if battle_manager:
		battle_manager.battle_started.connect(_on_battle_started)
		battle_manager.enemy_attacked.connect(_on_enemy_attacked)
		battle_manager.player_attacked.connect(_on_player_attacked)
		battle_manager.enemy_died.connect(_on_enemy_died)
		## 处理 battle_started 在连接前已发出的情况
		if battle_manager.enemy_data != null and battle_manager.enemy_data.is_alive():
			_on_battle_started(battle_manager.enemy_data)
	_update_appearance()

func _process(_delta: float) -> void:
	if current_enemy and current_enemy.is_alive():
		hp_bar.value = float(current_enemy.hp) / float(current_enemy.max_hp) * 100.0
	else:
		hp_bar.value = 0.0

func _on_battle_started(enemy: EnemyData) -> void:
	current_enemy = enemy
	body.modulate = Color.WHITE
	hp_bar.visible = true
	shadow.visible = true
	## 取消旧的死亡淡出，避免新敌人阴影被旧 tween 关闭
	if _death_tween != null and _death_tween.is_valid():
		_death_tween.kill()
		_death_tween = null
	_update_appearance()

func _on_enemy_attacked(_damage: int, _is_crit: bool) -> void:
	## 敌人攻击时稍微前冲
	var start_x: float = position.x
	var tween: Tween = create_tween()
	tween.tween_property(self, "position:x", start_x + 5.0, 0.05)
	tween.tween_property(self, "position:x", start_x, 0.05)

func _on_player_attacked(_damage: int, _is_crit: bool) -> void:
	body.modulate = Color(1.5, 1.5, 1.5, 1.0)
	hit_flash.start(0.1)
	var start_x: float = position.x
	var tween: Tween = create_tween()
	tween.tween_property(self, "position:x", start_x + 8.0, 0.05)
	tween.tween_property(self, "position:x", start_x, 0.05)

func _on_hit_flash_timer_timeout() -> void:
	body.modulate = Color.WHITE

func _on_enemy_died(_enemy: EnemyData) -> void:
	DeathParticles.spawn(get_tree().current_scene, global_position)
	## 死亡时停止待机动画、淡出并隐藏血条
	body.stop()
	hp_bar.visible = false
	## 停止受击闪烁定时器，避免其回调把 modulate 重置为白色打断死亡淡出
	hit_flash.stop()
	if _death_tween != null and _death_tween.is_valid():
		_death_tween.kill()
	_death_tween = create_tween()
	_death_tween.tween_property(body, "modulate", Color(1, 1, 1, 0), 0.5)
	_death_tween.tween_callback(func() -> void: shadow.visible = false)

func _update_appearance() -> void:
	if current_enemy == null:
		return

	var enemy_name: String = current_enemy.name
	if not ANIM_PATHS.has(enemy_name):
		var index: int = wrapi(current_enemy.level - 1, 0, FALLBACK_NAMES.size())
		enemy_name = FALLBACK_NAMES[index]

	_setup_sprite_frames(enemy_name)

	var s: float = current_enemy.size_scale
	scale = Vector2(s, s)
	hp_bar.max_value = 100
	hp_bar.value = 100

func _setup_sprite_frames(enemy_name: String) -> void:
	if _sprite_frames_cache.has(enemy_name):
		body.sprite_frames = _sprite_frames_cache[enemy_name]
		body.play("idle")
		return

	var path: String = ANIM_PATHS.get(enemy_name, ANIM_PATHS["史莱姆"]) as String
	var texture: Texture2D = load(path) as Texture2D
	if texture == null:
		push_warning("Failed to load enemy animation: %s" % path)
		return

	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", 6.0)

	var frame_count: int = 6
	var frame_width: float = texture.get_width() / float(frame_count)
	var frame_height: float = float(texture.get_height())

	for i: int in range(frame_count):
		var atlas: AtlasTexture = AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * frame_width, 0.0, frame_width, frame_height)
		frames.add_frame("idle", atlas)

	_sprite_frames_cache[enemy_name] = frames
	body.sprite_frames = frames
	body.play("idle")
