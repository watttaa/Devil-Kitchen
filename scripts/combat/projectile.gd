extends Area2D
## 投射物(任务 3.4):由对象池生成,直线飞行,命中 Hurtbox 或墙体后回收。
## collision_mask 决定能命中哪一阵营(由发射方在 spawn 时设置)。

var velocity: Vector2 = Vector2.ZERO
var damage: float = 10.0
var _alive: bool = false

@onready var visual: Polygon2D = $Vis
@onready var glow: Polygon2D = $Glow
@onready var life_timer: Timer = $LifeTimer

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	life_timer.timeout.connect(despawn)
	_set_dormant()

func spawn(pos: Vector2, dir: Vector2, speed: float, dmg: float, mask: int, color: Color, scl: float = 1.0) -> void:
	global_position = pos
	rotation = dir.angle()
	velocity = dir * speed
	damage = dmg
	collision_mask = mask
	visual.color = color
	glow.color = Color(color.r, color.g, color.b, 0.3)
	scale = Vector2.ONE * scl
	_alive = true
	visible = true
	monitoring = true
	life_timer.start()

func despawn() -> void:
	if not _alive:
		return
	_set_dormant()
	ProjectilePool.recycle(self)

func _set_dormant() -> void:
	_alive = false
	visible = false
	set_deferred("monitoring", false)
	velocity = Vector2.ZERO

## 由对象池在开新局时强制熄火(不重复回收)
func deactivate() -> void:
	_set_dormant()

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	global_position += velocity * delta

func _on_area_entered(area: Area2D) -> void:
	if not _alive:
		return
	if area.has_method("hit"):
		area.hit(damage)
		despawn()

func _on_body_entered(_body: Node) -> void:
	# 撞墙/障碍回收
	despawn()
