extends Node2D
class_name WallDecor
## 墙体装饰叠加:在墙面矩形上画瓷砖缝 + 顶部高光 + 踢脚线,读作厨房墙。
## 几何与 room.tscn 的墙体碰撞一致(局部坐标)。

const BANDS := [
	Rect2(-570, -350, 1140, 40),   # 上
	Rect2(-570, 310, 1140, 40),    # 下
	Rect2(-570, -330, 40, 250),    # 左上
	Rect2(-570, 80, 40, 250),      # 左下
	Rect2(530, -330, 40, 250),     # 右上
	Rect2(530, 80, 40, 250),       # 右下
]
const TILE := 48.0

@export var base: Color = Color(0.30, 0.27, 0.25)

func _draw() -> void:
	var seam := base.darkened(0.30)
	var hi := base.lightened(0.22)
	var lo := base.darkened(0.18)
	for item in BANDS:
		var b: Rect2 = item
		draw_rect(b, base)
		# 瓷砖缝
		var x: float = b.position.x + TILE
		while x < b.position.x + b.size.x:
			draw_line(Vector2(x, b.position.y), Vector2(x, b.position.y + b.size.y), seam, 1.0)
			x += TILE
		var y: float = b.position.y + TILE
		while y < b.position.y + b.size.y:
			draw_line(Vector2(b.position.x, y), Vector2(b.position.x + b.size.x, y), seam, 1.0)
			y += TILE
		# 内侧高光条 + 外侧暗边(简易立体)
		draw_line(b.position, Vector2(b.position.x + b.size.x, b.position.y), hi, 2.0)
		var bottom: float = b.position.y + b.size.y
		draw_line(Vector2(b.position.x, bottom), Vector2(b.position.x + b.size.x, bottom), lo, 2.0)
