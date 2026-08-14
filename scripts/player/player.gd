extends CharacterBody2D
## 玩家控制(任务 2.x / 3.x / 4.x)。
## 移动 + 鼠标瞄准;右键近战(无限);左键远程(消耗弹药);空格冲刺(无敌帧+冷却)。
## 近战/远程武器各占一个槽位,读 WeaponData 配置;可被拾取替换。

signal weapon_changed(melee_name: String, ranged_name: String)
signal ammo_changed(current: int, maximum: int)

const DEFAULT_MELEE := preload("res://resources/weapons/cleaver.tres")
const DEFAULT_RANGED := preload("res://resources/weapons/pepper.tres")
const PLAYER_PROJECTILE_MASK := 17  # 墙(1) + 敌人受击盒(16)
const HIT_IFRAME := 0.8             # 受击后无敌时长

@export var move_speed: float = 320.0
@export var dash_speed: float = 900.0
@export var dash_time: float = 0.15
@export var dash_cooldown: float = 0.6

var melee_weapon: WeaponData
var ranged_weapon: WeaponData
var ranged_ammo: int = 0

var _melee_cd: float = 0.0
var _melee_active: float = 0.0
var _melee_targets: Array = []
var _ranged_cd: float = 0.0
var _beam_line: Line2D
var _beam_active: bool = false
var _dashing: bool = false
var _dash_timer: float = 0.0
var _dash_cd: float = 0.0
var _dash_dir: Vector2 = Vector2.ZERO

# 局内构筑加成(由 RunContext / 食谱注入)
var bonus_damage_mult: float = 1.0
var bonus_attack_speed_mult: float = 1.0
var bonus_move_speed_mult: float = 1.0
var _temp_buff_mult: float = 1.0
var _temp_buff_timer: float = 0.0
var _hit_iframe: float = 0.0
var _last_hp: float = 0.0
var debug_god: bool = false
var _afterimage_cd: float = 0.0

@onready var aim_indicator: Node2D = $AimIndicator
@onready var melee_hitbox: Area2D = $MeleeHitbox
@onready var melee_shape: CollisionShape2D = $MeleeHitbox/MeleeCol
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health: Health = $Health
@onready var camera: Camera2D = $Camera2D
@onready var weapon_sprite: Sprite2D = $WeaponSprite

var _shake: float = 0.0
var _swing: float = 0.0

func _ready() -> void:
	add_to_group("player")
	($Body as ChefVisual).apply(SaveSystem.get_profile())
	melee_hitbox.monitoring = false
	# 起手武器:优先 RunContext 提供,否则默认
	var m: WeaponData = RunContext.starting_melee if RunContext.starting_melee else DEFAULT_MELEE
	var r: WeaponData = RunContext.starting_ranged if RunContext.starting_ranged else DEFAULT_RANGED
	set_melee_weapon(m)
	set_ranged_weapon(r, r.magazine_size)
	_last_hp = health.current
	health.health_changed.connect(_on_health_changed)
	_beam_line = Line2D.new()
	_beam_line.width = 10.0
	_beam_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_beam_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_beam_line.z_index = 5
	_beam_line.visible = false
	add_child(_beam_line)

func _on_health_changed(current: float, _maximum: float) -> void:
	if current < _last_hp:
		_hit_iframe = HIT_IFRAME
		_flash()
		_shake = 9.0
		GameManager.hitstop(0.12, 0.08)
	_last_hp = current

func _flash() -> void:
	var body := $Body
	var t := create_tween()
	t.set_loops(3)
	t.tween_property(body, "modulate", Color(1, 0.3, 0.3, 0.4), 0.12)
	t.tween_property(body, "modulate", Color(1, 1, 1, 1), 0.12)

func _physics_process(delta: float) -> void:
	_tick_timers(delta)

	if _dashing:
		velocity = _dash_dir * dash_speed
	else:
		var dir := _move_input()
		velocity = dir * move_speed * bonus_move_speed_mult
		_try_dash(dir)
		_try_melee()
		_try_ranged()
		if _seasoning_input():
			RunContext.use_any_seasoning()

	move_and_slide()
	_process_melee_hits()

func _process(delta: float) -> void:
	var aim := get_aim_direction()
	if aim.length() > 0.01:
		var ang := aim.angle()
		aim_indicator.rotation = ang
		var tex_off := 0.0
		if melee_weapon:
			tex_off = deg_to_rad(melee_weapon.texture_angle_offset)
		# 刀尖指向瞄准方向:tex_off 把贴图默认朝向对齐到 +x,再整体转 ang
		# flip_v 让刀刃恒朝屏幕下方(刀背朝上):瞄准偏右用正常,偏左镜像
		weapon_sprite.flip_v = false
		weapon_sprite.flip_h = false
		if aim.x < 0.0:
			# 指向左半边:水平镜像,避免刀倒挂,刃仍朝下
			weapon_sprite.flip_v = true
		weapon_sprite.rotation = ang + _swing + tex_off
		# 沿攻击方向外推,让武器伸到手的前方
		weapon_sprite.position = Vector2.RIGHT.rotated(ang) * 26.0
	if _shake > 0.0:
		camera.offset = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
		_shake = max(_shake - 45.0 * delta, 0.0)
	elif camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO

func _tick_timers(delta: float) -> void:
	_melee_cd = max(_melee_cd - delta, 0.0)
	_ranged_cd = max(_ranged_cd - delta, 0.0)
	_dash_cd = max(_dash_cd - delta, 0.0)
	_hit_iframe = max(_hit_iframe - delta, 0.0)
	hurtbox.invincible = _dashing or _hit_iframe > 0.0 or debug_god

	if _temp_buff_timer > 0.0:
		_temp_buff_timer -= delta
		if _temp_buff_timer <= 0.0:
			_temp_buff_mult = 1.0

	if _melee_active > 0.0:
		_melee_active -= delta
		if _melee_active <= 0.0:
			melee_hitbox.monitoring = false

	if _dashing:
		_dash_timer -= delta
		_afterimage_cd -= delta
		if _afterimage_cd <= 0.0:
			_spawn_afterimage()
			_afterimage_cd = 0.03
		if _dash_timer <= 0.0:
			_dashing = false

func _spawn_afterimage() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var ghost := ChefVisual.new()
	ghost.apply(SaveSystem.get_profile())
	parent.add_child(ghost)
	ghost.global_position = global_position
	ghost.z_index = -2
	ghost.modulate = Color(0.5, 0.7, 1.0, 0.45)
	var t := ghost.create_tween()
	t.tween_property(ghost, "modulate:a", 0.0, 0.25)
	t.tween_callback(ghost.queue_free)

func _try_dash(move_dir: Vector2) -> void:
	if _dash_cd > 0.0:
		return
	if _dash_input():
		_dash_dir = move_dir if move_dir.length() > 0.01 else get_aim_direction()
		_dashing = true
		_dash_timer = dash_time
		_dash_cd = dash_cooldown

func _try_melee() -> void:
	if melee_weapon == null or _melee_cd > 0.0:
		return
	if _melee_input():
		var aim := get_aim_direction()
		melee_hitbox.position = aim * melee_weapon.melee_range
		melee_hitbox.monitoring = true
		_melee_active = melee_weapon.melee_active_time
		_melee_cd = melee_weapon.attack_interval / bonus_attack_speed_mult
		_melee_targets.clear()
		_swing_weapon()

func _swing_weapon() -> void:
	var t := create_tween()
	_swing = -1.1
	t.tween_property(self, "_swing", 0.9, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "_swing", 0.0, 0.08)

func _process_melee_hits() -> void:
	if _melee_active <= 0.0 or melee_weapon == null:
		return
	var dmg := melee_weapon.damage * bonus_damage_mult * _temp_buff_mult * RunContext.combo_damage_mult()
	for area in melee_hitbox.get_overlapping_areas():
		if area in _melee_targets:
			continue
		if area.has_method("hit"):
			area.hit(dmg)
			if _melee_targets.is_empty():
				GameManager.hitstop(0.04, 0.05)
			_melee_targets.append(area)

func _ranged_infinite() -> bool:
	return ranged_weapon != null and ranged_weapon.type == WeaponData.Type.RANGED

func _try_ranged() -> void:
	if ranged_weapon == null:
		return
	if ranged_weapon.beam:
		_tick_beam()
		return
	if _ranged_cd > 0.0:
		return
	if _ranged_input():
		if not _ranged_infinite() and ranged_ammo <= 0:
			return
		_fire_ranged()
		if not _ranged_infinite():
			ranged_ammo -= 1
		_ranged_cd = ranged_weapon.attack_interval / bonus_attack_speed_mult
		ammo_changed.emit(ranged_ammo, ranged_weapon.magazine_size)

## 激光束:持续射线,命中敌人按 DPS*delta 持续掉血
func _tick_beam() -> void:
	var firing := _ranged_input() and (_ranged_infinite() or ranged_ammo > 0)
	if not firing:
		if _beam_active:
			_beam_active = false
			_beam_line.visible = false
		return
	_beam_active = true
	var aim := get_aim_direction()
	var muzzle := global_position + aim * 24.0
	var max_end := muzzle + aim * ranged_weapon.beam_length
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(muzzle, max_end, PLAYER_PROJECTILE_MASK)
	q.collide_with_areas = true
	q.collide_with_bodies = true
	var hit := space.intersect_ray(q)
	var end := max_end
	if hit:
		end = hit.position
		var col: Object = hit.collider
		if col is Hurtbox:
			var delta := get_physics_process_delta_time()
			var dps := ranged_weapon.damage * bonus_damage_mult * _temp_buff_mult * RunContext.combo_damage_mult()
			(col as Hurtbox).hit(dps * delta, false)
	# 视觉:本地坐标(Line2D 是 player 子节点)
	_beam_line.width = ranged_weapon.beam_width
	_beam_line.default_color = ranged_weapon.projectile_color
	_beam_line.points = PackedVector2Array([to_local(muzzle), to_local(end)])
	_beam_line.visible = true

func _fire_ranged() -> void:
	var aim := get_aim_direction()
	var muzzle := global_position + aim * 24.0
	var dmg := ranged_weapon.damage * bonus_damage_mult * _temp_buff_mult * RunContext.combo_damage_mult()
	var n: int = maxi(ranged_weapon.projectiles_per_shot, 1)
	var spread := deg_to_rad(ranged_weapon.spread_degrees)
	var jitter := deg_to_rad(ranged_weapon.fire_jitter_degrees)
	var scl: float = ranged_weapon.projectile_scale
	for i in n:
		var offset := 0.0
		if n > 1:
			offset = lerp(-spread * 0.5, spread * 0.5, float(i) / float(n - 1))
		if jitter > 0.0:
			offset += randf_range(-jitter, jitter)   # 机关枪/喷射流的扫射抖动
		var dir := aim.rotated(offset)
		ProjectilePool.fire(muzzle, dir, ranged_weapon.projectile_speed, dmg,
			PLAYER_PROJECTILE_MASK, ranged_weapon.projectile_color, scl)

# --- 武器槽位 API(供拾取替换调用) ---

## 设置近战武器,返回被替换的旧武器(可能为 null)
func set_melee_weapon(data: WeaponData) -> WeaponData:
	var old := melee_weapon
	melee_weapon = data
	if melee_shape.shape is CircleShape2D:
		(melee_shape.shape as CircleShape2D).radius = data.melee_radius
	_update_weapon_sprite()
	weapon_changed.emit(_name_of(melee_weapon), _name_of(ranged_weapon))
	return old

func _update_weapon_sprite() -> void:
	if melee_weapon and melee_weapon.texture:
		weapon_sprite.texture = melee_weapon.texture
		var w: float = maxi(melee_weapon.texture.get_width(), 1)
		weapon_sprite.scale = Vector2.ONE * (64.0 / w)
		# 支点=贴图中心;攻击端靠 texture_angle_offset 旋到 +x 后再外推
		weapon_sprite.offset = Vector2.ZERO
		weapon_sprite.visible = true
	else:
		weapon_sprite.visible = false

## 设置远程武器与弹药,返回被替换的旧武器(可能为 null)
func set_ranged_weapon(data: WeaponData, ammo: int) -> WeaponData:
	var old := ranged_weapon
	ranged_weapon = data
	ranged_ammo = ammo
	if _beam_line and (data == null or not data.beam):
		_beam_active = false
		_beam_line.visible = false
	weapon_changed.emit(_name_of(melee_weapon), _name_of(ranged_weapon))
	ammo_changed.emit(ranged_ammo, ranged_weapon.magazine_size)
	return old

func add_ammo(amount: int) -> void:
	if ranged_weapon == null:
		return
	ranged_ammo = min(ranged_ammo + amount, ranged_weapon.magazine_size)
	ammo_changed.emit(ranged_ammo, ranged_weapon.magazine_size)

func apply_temp_damage_buff(mult: float, duration: float) -> void:
	_temp_buff_mult = mult
	_temp_buff_timer = duration

func _name_of(w: WeaponData) -> String:
	return w.display_name if w else "—"

func get_aim_direction() -> Vector2:
	if TouchInput.enabled and TouchInput.aim_vec.length() > 0.01:
		return TouchInput.aim_vec.normalized()
	var aim := get_global_mouse_position() - global_position
	return aim.normalized() if aim.length() > 0.01 else Vector2.RIGHT

# --- 输入抽象:触屏优先,回退键鼠 ---

func _move_input() -> Vector2:
	if TouchInput.enabled:
		var v := TouchInput.move_vec
		return v if v.length() <= 1.0 else v.normalized()
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")

func _dash_input() -> bool:
	if TouchInput.enabled:
		return TouchInput.consume_dash()
	return Input.is_action_just_pressed("dash")

func _melee_input() -> bool:
	if TouchInput.enabled:
		return TouchInput.melee_held()
	return Input.is_action_pressed("melee_attack")

func _ranged_input() -> bool:
	if TouchInput.enabled:
		return TouchInput.firing
	return Input.is_action_pressed("ranged_attack")

func _seasoning_input() -> bool:
	if TouchInput.enabled:
		return TouchInput.consume_seasoning()
	return Input.is_action_just_pressed("use_seasoning")
