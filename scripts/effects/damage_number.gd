extends Label
## 飘字伤害数字:上浮 + 渐隐后自毁。setup(amount, crit) 设定文本/颜色。

func setup(amount: float, combo: int = 0) -> void:
	text = str(int(round(amount)))
	# 连击越高:字越大、颜色由暖白转金红
	var boost: float = clampf(float(combo) / 20.0, 0.0, 1.0)
	modulate = Color(1, 0.95, 0.6).lerp(Color(1, 0.5, 0.2), boost)
	_scale_boost = 1.0 + boost * 0.6

var _scale_boost: float = 1.0

func _ready() -> void:
	z_index = 200
	pivot_offset = size * 0.5
	# 从很小弹出,再明显放大到大字号(放大越猛,位图模糊越明显)
	var big: float = _scale_boost * 3.0
	scale = Vector2.ONE * (_scale_boost * 0.4)
	var rise := Vector2(randf_range(-18, 18), -60)
	var target := position + rise

	# 上浮:整段时间平滑上移
	var move := create_tween()
	move.tween_property(self, "position", target, 0.75).set_ease(Tween.EASE_OUT)

	# 放大:弹性超调到 big,带冲击感
	var grow := create_tween()
	grow.tween_property(self, "scale", Vector2.ONE * big, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# 渐隐后自毁
	var fade := create_tween()
	fade.tween_interval(0.4)
	fade.tween_property(self, "modulate:a", 0.0, 0.4)
	fade.tween_callback(queue_free)
