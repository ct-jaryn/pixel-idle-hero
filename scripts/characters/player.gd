extends Node2D

@export var data: PlayerData

@onready var body: AnimatedSprite2D = $Body
@onready var shadow: Polygon2D = $Shadow
@onready var hit_flash: Timer = $HitFlashTimer

const ANIM_PATHS: Dictionary = {
	"idle": "res://assets/images/animations/hero/hero_idle.png",
	"attack": "res://assets/images/animations/hero/hero_attack.png",
	"hit": "res://assets/images/animations/hero/hero_hit.png",
	"death": "res://assets/images/animations/hero/hero_death.png",
}

const ANIM_FRAMES: Dictionary = {
	"idle": 6,
	"attack": 6,
	"hit": 6,
	"death": 6,
}

const ANIM_FPS: Dictionary = {
	"idle": 5.0,
	"attack": 10.0,
	"hit": 8.0,
	"death": 6.0,
}

const ANIM_LOOP: Dictionary = {
	"idle": true,
	"attack": false,
	"hit": false,
	"death": false,
}

const BASE_SCALE: float = 1.0

var base_position: Vector2
var _is_dead: bool = false
var _breath_time: float = 0.0
## 当前进行中的攻击/受击动作 tween，用于在新的动作开始前清理旧的，避免位置漂移
var _action_tween: Tween = null

func _ready() -> void:
	base_position = position
	Services.player_node = self

	if data == null:
		data = Services.player_data

	var battle_manager: BattleManager = Services.battle_manager
	if battle_manager:
		battle_manager.enemy_attacked.connect(_on_enemy_attacked)
		battle_manager.player_attacked.connect(_on_player_attacked)
		battle_manager.player_died.connect(_on_player_died)

	_setup_sprite_frames()
	_update_appearance()
	body.animation_finished.connect(_on_animation_finished)
	body.play("idle")

func _setup_sprite_frames() -> void:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation("default")

	for anim_name: String in ANIM_PATHS.keys():
		var texture: Texture2D = load(ANIM_PATHS[anim_name]) as Texture2D
		if texture == null:
			push_warning("Failed to load hero animation: %s" % ANIM_PATHS[anim_name])
			continue

		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, ANIM_LOOP[anim_name])
		frames.set_animation_speed(anim_name, ANIM_FPS[anim_name])

		var frame_count: int = ANIM_FRAMES[anim_name]
		var frame_width: float = texture.get_width() / float(frame_count)
		var frame_height: float = float(texture.get_height())

		for i: int in range(frame_count):
			var atlas: AtlasTexture = AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(i * frame_width, 0.0, frame_width, frame_height)
			frames.add_frame(anim_name, atlas)

	body.sprite_frames = frames

func _process(delta: float) -> void:
	## 待机呼吸位移动画（使用 delta 累加，避免帧率绑定和每秒跳变）
	if not _is_dead:
		_breath_time += delta
		position.y = base_position.y + sin(_breath_time * 2.0) * 2.0
		## 没有动作 tween 在跑时，把 x 平滑拉回基础位置，防止快速攻击打断 tween 后产生漂移
		if _action_tween == null or not _action_tween.is_valid():
			position.x = lerpf(position.x, base_position.x, clampf(delta * 25.0, 0.0, 1.0))

func _update_appearance() -> void:
	if data == null:
		return
	## 随等级略微变大
	var scale_factor: float = BASE_SCALE + (data.level - 1) * 0.02
	scale = Vector2(scale_factor, scale_factor)

func _play_animation(anim_name: String) -> void:
	if _is_dead and anim_name != "death":
		return
	if body.sprite_frames.has_animation(anim_name):
		body.play(anim_name)

func _on_animation_finished() -> void:
	if _is_dead:
		return
	if body.animation != "idle":
		body.play("idle")

func _on_enemy_attacked(damage: int, is_crit: bool) -> void:
	if _is_dead:
		return
	_play_animation("hit")
	body.modulate = Color.RED
	hit_flash.start(0.1)
	_knockback(is_crit)
	_show_floating_text(damage, is_crit, false)

func _on_player_attacked(damage: int, is_crit: bool) -> void:
	if _is_dead:
		return
	_play_animation("attack")
	_lunge_forward(is_crit)
	_show_floating_text(damage, is_crit, true)

## 清理进行中的动作 tween，避免与新的攻击/受击叠加造成位置与缩放漂移
func _kill_action_tween() -> void:
	if _action_tween != null and _action_tween.is_valid():
		_action_tween.kill()
	_action_tween = null

## 攻击：先后撤蓄力，再向敌人(右侧)突进，最后回收，配合身体的挤压拉伸增强打击感
func _lunge_forward(is_crit: bool) -> void:
	_kill_action_tween()
	var dist: float = 32.0 if is_crit else 24.0
	var t: Tween = create_tween()
	# 蓄力：微微后撤 + 纵向拉长
	t.tween_property(self, "position:x", base_position.x - 6.0, 0.03).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(body, "scale", Vector2(0.9, 1.1), 0.03)
	# 突进：向前冲 + 横向拉伸
	t.tween_property(self, "position:x", base_position.x + dist, 0.06).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(body, "scale", Vector2(1.15, 0.9), 0.06)
	# 回收：回到基础位置 + 恢复比例
	t.tween_property(self, "position:x", base_position.x, 0.10).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(body, "scale", Vector2.ONE, 0.10)
	_action_tween = t

## 受击：向远离敌人(左侧)方向击退，身体被压扁，暴击击退更远
func _knockback(is_crit: bool) -> void:
	_kill_action_tween()
	var dist: float = 14.0 if is_crit else 9.0
	var t: Tween = create_tween()
	t.tween_property(self, "position:x", base_position.x - dist, 0.06).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(body, "scale", Vector2(1.18, 0.85), 0.06)
	t.tween_property(self, "position:x", base_position.x, 0.12).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(body, "scale", Vector2.ONE, 0.12)
	_action_tween = t

func _on_player_died() -> void:
	_is_dead = true
	_kill_action_tween()
	body.scale = Vector2.ONE
	position = base_position
	_play_animation("death")

func revive() -> void:
	_is_dead = false
	_kill_action_tween()
	body.scale = Vector2.ONE
	body.modulate = Color.WHITE
	position = base_position
	_play_animation("idle")

func _show_floating_text(damage: int, is_crit: bool, is_player_attacking: bool) -> void:
	var ftm: FloatingTextManager = Services.floating_text_manager
	if ftm == null:
		return
	if is_player_attacking:
		ftm.show_damage(global_position + Vector2(0, -40), damage, true, is_crit)
	else:
		ftm.show_damage(global_position + Vector2(0, -40), damage, false, is_crit)

func _on_hit_flash_timer_timeout() -> void:
	body.modulate = Color.WHITE
