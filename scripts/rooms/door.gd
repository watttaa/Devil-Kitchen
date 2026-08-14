extends StaticBody2D
class_name RoomDoor
## 房间门:三态视觉反馈。
## OPEN 绿色半透明可穿过;LOCKED 红色脉动挡路(战斗中);SEALED 墙色永久封死(无门侧)。

enum DoorState { OPEN, LOCKED, SEALED }

const OPEN_COLOR := Color(0.35, 0.75, 0.4, 0.4)
const LOCKED_COLOR := Color(0.78, 0.22, 0.22, 1)
const SEALED_COLOR := Color(0.33, 0.3, 0.27, 1)

@onready var vis: Polygon2D = $Vis
@onready var col: CollisionShape2D = $Col

var state: int = DoorState.OPEN
var _pulse: float = 0.0

func lock() -> void:
	_apply(DoorState.LOCKED)

func open_door() -> void:
	_apply(DoorState.OPEN)

func seal() -> void:
	_apply(DoorState.SEALED)

func _apply(s: int) -> void:
	var changed := state != s
	state = s
	visible = true
	match s:
		DoorState.OPEN:
			col.set_deferred("disabled", true)
			vis.color = OPEN_COLOR
			if changed:
				_play(Vector2(0.4, 1.0))
		DoorState.LOCKED:
			col.set_deferred("disabled", false)
			vis.color = LOCKED_COLOR
			if changed:
				_play(Vector2(1.0, 0.4))
		DoorState.SEALED:
			col.set_deferred("disabled", false)
			vis.color = SEALED_COLOR

func _process(delta: float) -> void:
	if state != DoorState.LOCKED:
		return
	_pulse += delta * 4.5
	var a: float = 0.65 + 0.35 * sin(_pulse)
	vis.color = Color(LOCKED_COLOR.r, LOCKED_COLOR.g, LOCKED_COLOR.b, a)

func _play(from: Vector2) -> void:
	vis.scale = from
	var tw := create_tween()
	tw.tween_property(vis, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
