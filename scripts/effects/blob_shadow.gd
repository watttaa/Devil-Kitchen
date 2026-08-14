extends Node2D
class_name BlobShadow
## 脚下椭圆投影:立体感 + 可读性。挂到实体上,置于本体之下先绘制。

@export var radius: float = 16.0
@export var squash: float = 0.45   # 垂直压扁比例
@export var color: Color = Color(0, 0, 0, 0.26)

func _ready() -> void:
	z_index = -1

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, squash))
	draw_circle(Vector2.ZERO, radius, color)
