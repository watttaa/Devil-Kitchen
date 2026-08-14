extends Area2D
class_name Hitbox
## 攻击盒(任务 3.1):重叠到对方 Hurtbox 时造成伤害。
## 通过 collision_mask 只检测对方阵营的 hurtbox 层,实现敌我过滤。

@export var damage: float = 10.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("hit"):
		area.hit(damage)
