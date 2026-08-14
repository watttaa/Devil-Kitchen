extends Control
class_name TouchJoystick
## 虚拟摇杆:触摸落在控件内即激活,输出归一化向量(长度 0..1)。
## is_move=true 写 TouchInput.set_move,否则写 set_aim。自绘,无需贴图。

@export var is_move: bool = true
@export var radius: float = 90.0

var _touch_id: int = -1
var _center: Vector2
var _knob: Vector2 = Vector2.ZERO
var _value: Vector2 = Vector2.ZERO

func _ready() -> void:
	_center = size * 0.5
	# 非触屏设备:彻底不拦截鼠标,避免盖住暂停菜单等 UI
	if not TouchInput.enabled:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		visible = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_id == -1:
			_touch_id = event.index
			_center = event.position
			_update(event.position)
			accept_event()
		elif not event.pressed and event.index == _touch_id:
			_release()
			accept_event()
	elif event is InputEventScreenDrag and event.index == _touch_id:
		_update(event.position)
		accept_event()

func _update(pos: Vector2) -> void:
	var off := pos - _center
	if off.length() > radius:
		off = off.normalized() * radius
	_knob = off
	_value = off / radius
	_emit()
	queue_redraw()

func _release() -> void:
	_touch_id = -1
	_value = Vector2.ZERO
	_knob = Vector2.ZERO
	_center = size * 0.5
	_emit()
	queue_redraw()

func _emit() -> void:
	if is_move:
		TouchInput.set_move(_value)
	else:
		TouchInput.set_aim(_value)

func _draw() -> void:
	var base_col := Color(1, 1, 1, 0.18)
	var knob_col := Color(1, 1, 1, 0.45) if is_move else Color(1, 0.6, 0.3, 0.6)
	draw_circle(_center, radius, base_col)
	draw_circle(_center + _knob, radius * 0.45, knob_col)
