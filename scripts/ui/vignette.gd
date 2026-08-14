extends ColorRect
## 暗角脚本:每帧把玩家血量比例喂给 shader,低血时红色渐显。

var _mat: ShaderMaterial

func _ready() -> void:
	_mat = material as ShaderMaterial
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	if _mat == null:
		return
	var p := get_tree().get_first_node_in_group("player")
	if p and p.health and p.health.max_health > 0.0:
		_mat.set_shader_parameter("hp_frac", clampf(p.health.current / p.health.max_health, 0.0, 1.0))
	else:
		_mat.set_shader_parameter("hp_frac", 1.0)
