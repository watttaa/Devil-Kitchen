extends CharacterBody2D
class_name Boss
## 大厨 Boss(任务 10.x):随血量分 3 阶段,弹幕越来越密。
## 死亡发出 defeated → 房间触发通关。属于 "enemies" 组(可被减速)。

signal defeated

const ENEMY_PROJECTILE_MASK := 9
const BULLET_COLOR := Color(1, 0.35, 0.6)   # Boss 子弹亮粉,辨识度高
const HIT_SPARK := preload("res://scenes/hit_spark.tscn")
const BOSS_TEXTURES := [
	preload("res://kenney_food-kit/Previews/burger-cheese-double.png"),
	preload("res://kenney_food-kit/Previews/burger-double.png"),
	preload("res://kenney_food-kit/Previews/cake-birthday.png"),
]

@export var max_health: float = 600.0
@export var move_speed: float = 110.0
@export var color: Color = Color(0.6, 0.12, 0.5)
@export var body_radius: float = 48.0
@export var contact_damage: float = 1.0

var _player: Node2D = null
var _fire_cd: float = 0.0
var _spiral_angle: float = 0.0
var _contact_cd: float = 0.0
var _slow_factor: float = 1.0
var _slow_timer: float = 0.0
var _knockback: Vector2 = Vector2.ZERO
var _stun_timer: float = 0.0
var _base_scale: Vector2 = Vector2.ONE

@onready var health: Health = $Health
@onready var contact: Area2D = $Contact
@onready var vis: Sprite2D = $Vis

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	var s := _floor_scale()
	health.max_health = max_health * s
	health.current = max_health * s
	health.died.connect(_on_died)
	health.damaged.connect(_on_hurt)
	var f := clampi(RunContext.current_floor - 1, 0, BOSS_TEXTURES.size() - 1)
	vis.texture = BOSS_TEXTURES[f]
	if vis.texture:
		var w: float = maxi(vis.texture.get_width(), 1)
		vis.scale = Vector2.ONE * (body_radius * 2.4 / w)
	_base_scale = vis.scale

## 楼层难度缩放:第 N 层 Boss 血量×(1 + 0.5*(N-1)),第 1 层=1
func _floor_scale() -> float:
	return 1.0 + 0.5 * (RunContext.current_floor - 1)

func _on_hurt(_amount: float) -> void:
	_stun_timer = 0.12
	if _player:
		_knockback = (global_position - _player.global_position).normalized() * 140.0
	var parent := get_parent()
	if parent:
		var sp := HIT_SPARK.instantiate()
		parent.add_child(sp)
		sp.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	var base := _base_scale
	var t := create_tween()
	t.tween_property(vis, "modulate", Color(2.2, 2.2, 2.2), 0.04)
	t.tween_property(vis, "modulate", Color.WHITE, 0.1)
	var t2 := create_tween()
	t2.tween_property(vis, "scale", base * 1.1, 0.05).set_trans(Tween.TRANS_BACK)
	t2.tween_property(vis, "scale", base, 0.08)

func _phase() -> int:
	var f := health.current / health.max_health
	if f > 0.66:
		return 1
	elif f > 0.33:
		return 2
	return 3

func _physics_process(delta: float) -> void:
	_fire_cd = max(_fire_cd - delta, 0.0)
	_contact_cd = max(_contact_cd - delta, 0.0)
	_stun_timer = max(_stun_timer - delta, 0.0)
	_knockback = _knockback.move_toward(Vector2.ZERO, 600.0 * delta)
	if _knockback.length_squared() > 1.0:
		global_position += _knockback * delta
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_slow_factor = 1.0

	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		return
	if _stun_timer > 0.0:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_player := _player.global_position - global_position
	var ph := _phase()
	var spd := move_speed * (1.0 + 0.25 * (ph - 1)) * _slow_factor
	velocity = to_player.normalized() * spd
	move_and_slide()
	_contact_damage()

	if _fire_cd <= 0.0:
		_attack(ph, to_player.normalized())

func _attack(phase: int, aim: Vector2) -> void:
	var f := clampi(RunContext.current_floor, 1, 3)
	match f:
		1:
			# 汉堡塔:径向 + 瞄准连射
			match phase:
				1:
					_radial(8, 0.0)
					_fire_cd = 1.4
				2:
					_spiral(3)
					_fire_cd = 0.5
				3:
					_radial(12, 0.0)
					_aimed_burst(aim, 3)
					_fire_cd = 0.9
		2:
			# 双层堡:更密螺旋 + 双向径向
			match phase:
				1:
					_radial(10, 0.0)
					_fire_cd = 1.2
				2:
					_spiral(4)
					_radial(6, PI / 6.0)
					_fire_cd = 0.55
				3:
					_radial(16, 0.0)
					_aimed_burst(aim, 4)
					_fire_cd = 0.75
		3:
			# 生日蛋糕:爆裂弹幕 + 追踪
			match phase:
				1:
					_radial(12, 0.0)
					_aimed_burst(aim, 2)
					_fire_cd = 1.1
				2:
					_spiral(5)
					_radial(10, PI / 5.0)
					_fire_cd = 0.45
				3:
					_radial(20, 0.0)
					_aimed_burst(aim, 5)
					_spiral(3)
					_fire_cd = 0.6

func _radial(n: int, offset: float) -> void:
	for i in n:
		var dir := Vector2.RIGHT.rotated(offset + TAU * i / n)
		_fire(dir, 320.0)

func _spiral(n: int) -> void:
	for i in n:
		var dir := Vector2.RIGHT.rotated(_spiral_angle + TAU * i / n)
		_fire(dir, 360.0)
	_spiral_angle += 0.4

func _aimed_burst(aim: Vector2, n: int) -> void:
	var base := aim.angle()
	for i in n:
		var dir := Vector2.RIGHT.rotated(base + deg_to_rad((i - (n - 1) / 2.0) * 12.0))
		_fire(dir, 420.0)

func _fire(dir: Vector2, speed: float) -> void:
	ProjectilePool.fire(global_position + dir * (body_radius + 8.0), dir,
		speed, 1.0, ENEMY_PROJECTILE_MASK, BULLET_COLOR)

func _contact_damage() -> void:
	if _contact_cd > 0.0:
		return
	for area in contact.get_overlapping_areas():
		if area.has_method("hit"):
			area.hit(contact_damage * _floor_scale())
			_contact_cd = 0.7
			break

func apply_slow(factor: float, duration: float) -> void:
	_slow_factor = clampf(1.0 - factor, 0.1, 1.0)
	_slow_timer = duration

func _on_died() -> void:
	var parent := get_parent()
	if parent:
		for i in 5:
			var sp := HIT_SPARK.instantiate()
			parent.add_child(sp)
			sp.global_position = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
	GameManager.hitstop(0.15, 0.45)
	defeated.emit()
	queue_free()
