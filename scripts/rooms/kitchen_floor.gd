extends Node2D
class_name KitchenFloor
## 矢量厨房地板:棋盘瓷砖 + 勾缝线。颜色由房间类型决定(set_base)。

@export var size: Vector2 = Vector2(1100, 660)
@export var tile: float = 55.0
@export var base_color: Color = Color(0.16, 0.14, 0.18)

func set_base(c: Color) -> void:
	base_color = c
	queue_redraw()

func _draw() -> void:
	var origin := -size * 0.5
	var cols := int(size.x / tile)
	var rows := int(size.y / tile)
	var light := base_color.lightened(0.10)
	var dark := base_color.darkened(0.10)
	var accent := base_color.lightened(0.18)
	for y in rows:
		for x in cols:
			var col := light if (x + y) % 2 == 0 else dark
			# 少量点缀瓷砖(固定图案,换个色相增加层次)
			if (x * 3 + y * 7) % 17 == 0:
				col = accent
			draw_rect(Rect2(origin + Vector2(x * tile, y * tile), Vector2(tile, tile)), col)
	# 勾缝线
	var grout := base_color.darkened(0.35)
	for x in range(cols + 1):
		var gx := origin.x + x * tile
		draw_line(Vector2(gx, origin.y), Vector2(gx, origin.y + size.y), grout, 1.5)
	for y in range(rows + 1):
		var gy := origin.y + y * tile
		draw_line(Vector2(origin.x, gy), Vector2(origin.x + size.x, gy), grout, 1.5)
	# 油渍/水渍(固定位置,半透明压暗)
	draw_circle(Vector2(-size.x * 0.28, -size.y * 0.18), 62.0, Color(0, 0, 0, 0.06))
	draw_circle(Vector2(size.x * 0.22, size.y * 0.22), 84.0, Color(0, 0, 0, 0.06))
	draw_circle(Vector2(size.x * 0.12, -size.y * 0.26), 40.0, Color(0.1, 0.05, 0, 0.05))
	# 边缘压暗:嵌套描边,越靠边越暗
	for k in 5:
		var inset := k * 9.0
		var rect := Rect2(origin + Vector2(inset, inset), size - Vector2(inset * 2.0, inset * 2.0))
		draw_rect(rect, Color(0, 0, 0, 0.05), false, 9.0)
