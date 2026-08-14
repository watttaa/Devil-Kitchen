extends Area2D
class_name Hurtbox
## 受击盒(任务 3.1):被攻击命中时把伤害转给绑定的 Health。
## 默认自动查找同级名为 "Health" 的节点,避免依赖场景里的 NodePath 序列化。

@export var health: Health
var invincible: bool = false

const DMG_NUMBER := preload("res://scenes/damage_number.tscn")

func _ready() -> void:
	if health == null:
		var p := get_parent()
		if p != null and p.has_node("Health"):
			health = p.get_node("Health") as Health

## 由命中方调用
func hit(amount: float) -> void:
	if invincible or health == null:
		return
	health.take_damage(amount)
	_popup_number(amount)

func _popup_number(amount: float) -> void:
	var p := get_parent()
	if p == null or not p.is_in_group("enemies"):
		return
	var n := DMG_NUMBER.instantiate()
	var scene := get_tree().current_scene
	if scene == null:
		return
	scene.add_child(n)
	n.global_position = (p as Node2D).global_position + Vector2(-18, -34)
	n.setup(amount, RunContext.combo)
