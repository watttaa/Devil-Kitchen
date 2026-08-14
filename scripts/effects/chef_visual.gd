extends Node2D
class_name ChefVisual
## 可复用的矢量小厨师形象:玩家本体 / 捧脸预览 / 主菜单立绘共用。
## 颜色与配饰由 profile 决定,apply() 后重绘。

var BODY_POLY := PackedVector2Array([
	Vector2(-14, -20), Vector2(14, -20), Vector2(20, -14), Vector2(20, 14),
	Vector2(14, 20), Vector2(-14, 20), Vector2(-20, 14), Vector2(-20, -14)])
var APRON_POLY := PackedVector2Array([
	Vector2(-12, 2), Vector2(12, 2), Vector2(9, 20), Vector2(-9, 20)])
var HATBAND_POLY := PackedVector2Array([
	Vector2(-16, -22), Vector2(16, -22), Vector2(16, -16), Vector2(-16, -16)])
var HAT_POLY := PackedVector2Array([
	Vector2(-15, -22), Vector2(-16, -32), Vector2(-8, -38), Vector2(0, -33),
	Vector2(8, -38), Vector2(16, -32), Vector2(15, -22)])

@export var body_color: Color = Color(0.36, 0.72, 1)
@export var hat_color: Color = Color(1, 1, 1)
@export var accent_color: Color = Color(0.9, 0.3, 0.35)
@export var accessory: int = 0   # 0无 1墨镜 2胡子 3围巾 4领结

func apply(p: Dictionary) -> void:
	body_color = _to_color(p.get("body", body_color))
	hat_color = _to_color(p.get("hat", hat_color))
	accent_color = _to_color(p.get("accent", accent_color))
	accessory = int(p.get("accessory", accessory))
	queue_redraw()

func _to_color(v: Variant) -> Color:
	if v is Color:
		return v
	if v is Array and v.size() >= 3:
		return Color(v[0], v[1], v[2])
	return Color.WHITE

func _draw() -> void:
	# 身体 + 围裙
	draw_colored_polygon(BODY_POLY, body_color)
	draw_colored_polygon(APRON_POLY, Color(0.96, 0.96, 0.98))
	# 帽箍 + 帽子
	draw_colored_polygon(HATBAND_POLY, Color(0.96, 0.96, 0.98))
	draw_colored_polygon(HAT_POLY, hat_color)
	# 腮红
	draw_circle(Vector2(-9, 6), 3.2, Color(1, 0.6, 0.55, 0.7))
	draw_circle(Vector2(9, 6), 3.2, Color(1, 0.6, 0.55, 0.7))
	# 眼睛
	_eye(Vector2(-7, -6))
	_eye(Vector2(7, -6))
	# 配饰
	match accessory:
		1: _sunglasses()
		2: _mustache()
		3: _scarf()
		4: _bowtie()

func _eye(c: Vector2) -> void:
	draw_rect(Rect2(c.x - 2.5, c.y - 3, 5, 6), Color(0.12, 0.12, 0.18))

func _sunglasses() -> void:
	draw_rect(Rect2(-11, -9, 8, 6), Color(0.08, 0.08, 0.1))
	draw_rect(Rect2(3, -9, 8, 6), Color(0.08, 0.08, 0.1))
	draw_line(Vector2(-3, -6), Vector2(3, -6), Color(0.08, 0.08, 0.1), 2.0)

func _mustache() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(-9, 2), Vector2(0, 0), Vector2(9, 2), Vector2(4, 6),
		Vector2(0, 3), Vector2(-4, 6)]), Color(0.2, 0.15, 0.12))

func _scarf() -> void:
	draw_rect(Rect2(-15, 0, 30, 5), accent_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(8, 3), Vector2(15, 3), Vector2(13, 16), Vector2(8, 14)]), accent_color)

func _bowtie() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8, -20), Vector2(-1, -18), Vector2(-8, -14)]), accent_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(8, -20), Vector2(1, -18), Vector2(8, -14)]), accent_color)
	draw_circle(Vector2(0, -18), 2.0, accent_color.darkened(0.2))
