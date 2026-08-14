extends CharacterBody2D
class_name Enemy
## 食材怪基类(任务 5.x):FSM(待机/追击/攻击)+ 三种行为 + 接触伤害 + 掉落 + 减速。
## 由 EnemyData 配置驱动。死亡时 defeated 信号通知房间。

signal defeated

const PICKUP_SCENE := preload("res://scenes/pickup.tscn")
const HIT_SPARK := preload("res://scenes/hit_spark.tscn")
const ENEMY_PROJECTILE_MASK := 9   # 墙(1) + 玩家受击盒(8)
const BULLET_COLOR := Color(1, 0.5, 0.12)   # 敌人子弹统一亮橙,高辨识度

@export var data: EnemyData

var _attack_cd: float = 0.0
var _contact_cd: float = 0.0
var _slow_factor: float = 1.0
var _slow_timer: float = 0.0
var _player: Node2D = null
var _knockback: Vector2 = Vector2.ZERO
var _base_scale: Vector2 = Vector2.ONE
var _stun_timer: float = 0.0
var _bob_phase: float = 0.0

@onready var vis: Sprite2D = $Vis
@onready var body_col: CollisionShape2D = $Col
@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var contact: Area2D = $Contact

func _ready() -> void:
	add_to_group("enemies")
	_bob_phase = randf() * TAU
	if data:
		_apply_data()
		_spawn_pop()
	health.died.connect(_on_died)
	health.damaged.connect(_on_hurt)

func _spawn_pop() -> void:
	vis.scale = Vector2.ZERO
	var t := create_tween()
	t.tween_property(vis, "scale", _base_scale, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _apply_data() -> void:
	var s := _floor_scale()
	health.max_health = data.max_health * s
	health.current = data.max_health * s
	var r := data.body_radius
	if data.texture:
		vis.texture = data.texture
		var w: float = maxi(data.texture.get_width(), 1)
		vis.scale = Vector2.ONE * (r * 2.4 / w)
	else:
		vis.modulate = data.color
	_base_scale = vis.scale
	if body_col.shape is CircleShape2D:
		(body_col.shape as CircleShape2D).radius = r
	for c in [$Hurtbox/HurtCol, $Contact/ContactCol]:
		if c.shape is CircleShape2D:
			(c.shape as CircleShape2D).radius = r + 4.0

## 楼层难度缩放:第 N 层敌人血量×(1 + 0.35*(N-1)),第 1 层=1
func _floor_scale() -> float:
	return 1.0 + 0.35 * (RunContext.current_floor - 1)

func _physics_process(delta: float) -> void:
	_tick(delta)
	_player = get_tree().get_first_node_in_group("player")
	if _player == null or data == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_player := _player.global_position - global_position
	var dist := to_player.length()
	if _stun_timer > 0.0:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	match data.behavior:
		EnemyData.Behavior.CHASER:
			_do_chaser(to_player, dist)
		EnemyData.Behavior.TURRET:
			_do_turret(dist)
		EnemyData.Behavior.SHOOTER:
			_do_shooter(to_player, dist)
	_contact_damage()

func _tick(delta: float) -> void:
	_attack_cd = max(_attack_cd - delta, 0.0)
	_contact_cd = max(_contact_cd - delta, 0.0)
	_stun_timer = max(_stun_timer - delta, 0.0)
	_bob_phase += delta * 4.5
	if _stun_timer <= 0.0:
		vis.position.y = sin(_bob_phase) * 2.5
	_knockback = _knockback.move_toward(Vector2.ZERO, 700.0 * delta)
	if _knockback.length_squared() > 1.0:
		global_position += _knockback * delta
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_slow_factor = 1.0

func _on_hurt(_amount: float) -> void:
	_stun_timer = 0.3
	if _player:
		_knockback = (global_position - _player.global_position).normalized() * 420.0
	_spawn_spark()
	var base := _base_scale
	var t := create_tween()
	t.tween_property(vis, "modulate", Color(2.2, 2.2, 2.2), 0.04)
	t.tween_property(vis, "modulate", Color.WHITE, 0.12)
	var t2 := create_tween()
	t2.tween_property(vis, "scale", base * 1.18, 0.05).set_trans(Tween.TRANS_BACK)
	t2.tween_property(vis, "scale", base, 0.09)

func _spawn_spark() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var sp := HIT_SPARK.instantiate()
	var pos := global_position
	parent.add_child.call_deferred(sp)
	sp.set_deferred("global_position", pos)

func _do_chaser(to_player: Vector2, dist: float) -> void:
	if dist <= data.sense_range:
		velocity = to_player.normalized() * data.move_speed * _slow_factor
	else:
		velocity = Vector2.ZERO
	move_and_slide()

func _do_turret(dist: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	if dist <= data.sense_range and _attack_cd <= 0.0:
		_radial_burst()
		_attack_cd = data.attack_interval

func _do_shooter(to_player: Vector2, dist: float) -> void:
	var dir := to_player.normalized()
	if dist <= data.sense_range:
		if dist > data.attack_range * 1.15:
			velocity = dir * data.move_speed * _slow_factor
		elif dist < data.attack_range * 0.7:
			velocity = -dir * data.move_speed * _slow_factor
		else:
			velocity = Vector2.ZERO
		move_and_slide()
		if _attack_cd <= 0.0:
			_fire(dir)
			_attack_cd = data.attack_interval
	else:
		velocity = Vector2.ZERO
		move_and_slide()

func _radial_burst() -> void:
	var n := 8
	for i in n:
		var dir := Vector2.RIGHT.rotated(TAU * i / n)
		_fire(dir)

func _fire(dir: Vector2) -> void:
	ProjectilePool.fire(global_position + dir * (data.body_radius + 6.0), dir,
		data.projectile_speed, data.projectile_damage * _floor_scale(),
		ENEMY_PROJECTILE_MASK, data.color)

func _contact_damage() -> void:
	if _contact_cd > 0.0:
		return
	for area in contact.get_overlapping_areas():
		if area.has_method("hit"):
			area.hit(data.contact_damage * _floor_scale())
			_contact_cd = 0.6
			break

## 调料减速效果(SLOW_ENEMIES)
func apply_slow(factor: float, duration: float) -> void:
	_slow_factor = clampf(1.0 - factor, 0.1, 1.0)
	_slow_timer = duration

func _on_died() -> void:
	SaveSystem.add_kill(1, data.id if data else "")
	RunContext.register_kill()
	_death_poof()
	_drop_loot()
	defeated.emit()
	queue_free()

func _death_poof() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var sp := HIT_SPARK.instantiate()
	sp.scale = Vector2(1.6, 1.6)
	var pos := global_position
	parent.add_child.call_deferred(sp)
	sp.set_deferred("global_position", pos)

func _drop_loot() -> void:
	var parent := get_parent()
	if parent == null:
		return
	if data.tips_drop > 0:
		_spawn_pickup(parent, Pickup.Kind.TIPS, data.tips_drop, Vector2(8, 0))
	if RunContext.rng.randf() < data.ammo_drop_chance and not _player_has_infinite_ammo():
		_spawn_pickup(parent, Pickup.Kind.AMMO, data.ammo_amount, Vector2(-8, 8))

func _player_has_infinite_ammo() -> bool:
	# 远程武器一律无限,恒不掉弹药
	return true

func _spawn_pickup(parent: Node, kind: int, amount: int, offset: Vector2) -> void:
	var pk := PICKUP_SCENE.instantiate()
	pk.kind = kind
	pk.amount = amount
	var pos := global_position + offset
	parent.add_child.call_deferred(pk)
	pk.set_deferred("global_position", pos)
