extends Node
## 投射物对象池(任务 3.4):复用投射物节点,避免频繁实例化造成卡顿。
## 作为 Autoload。投射物作为本池子节点的子节点常驻场景树。

const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const PREWARM := 48

var _pool: Array = []

func _ready() -> void:
	for i in PREWARM:
		var p := _make()
		_pool.append(p)

func _make() -> Area2D:
	var p: Area2D = PROJECTILE_SCENE.instantiate()
	add_child(p)
	return p

## 取一颗投射物并发射
func fire(pos: Vector2, dir: Vector2, speed: float, dmg: float, mask: int, color: Color, scl: float = 1.0) -> void:
	var p: Area2D
	if _pool.is_empty():
		p = _make()
	else:
		p = _pool.pop_back()
	p.spawn(pos, dir, speed, dmg, mask, color, scl)

func recycle(p: Area2D) -> void:
	_pool.append(p)

## 开新局时清空:让所有在飞子弹熄火,重建空闲池(防止跨场景残留子弹误伤)
func clear_all() -> void:
	_pool.clear()
	for c in get_children():
		var p := c as Area2D
		p.deactivate()
		_pool.append(p)
