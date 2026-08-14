extends Node2D
## 训练靶(任务 3.6):受击扣血、显示血量、受击闪烁、死亡移除。
## 用于验证近战/远程命中与冲刺无敌。

@onready var health: Health = $Health
@onready var label: Label = $HpLabel

func _ready() -> void:
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	label.text = str(int(health.max_health))

func _on_health_changed(current: float, _maximum: float) -> void:
	label.text = str(int(current))
	modulate = Color(1, 0.5, 0.5)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.15)

func _on_died() -> void:
	queue_free()
