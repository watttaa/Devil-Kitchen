extends CPUParticles2D
## 一次性命中火花:_ready 触发,播完自毁。

func _ready() -> void:
	one_shot = true
	emitting = true
	finished.connect(queue_free)

func tint(c: Color) -> void:
	color = c
