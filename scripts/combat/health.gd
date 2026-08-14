extends Node
class_name Health
## 通用生命组件(任务 3.1):挂在玩家/敌人/靶子下,统一处理扣血与死亡。

signal health_changed(current: float, maximum: float)
signal damaged(amount: float)
signal died

@export var max_health: float = 100.0
var current: float

func _ready() -> void:
	current = max_health

func take_damage(amount: float) -> void:
	if current <= 0.0:
		return
	current = max(current - amount, 0.0)
	damaged.emit(amount)
	health_changed.emit(current, max_health)
	if current <= 0.0:
		died.emit()

func heal(amount: float) -> void:
	if current <= 0.0:
		return
	current = min(current + amount, max_health)
	health_changed.emit(current, max_health)
