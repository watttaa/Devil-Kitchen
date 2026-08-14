extends Node
## 触屏输入聚合(移动端)。虚拟摇杆/按钮把状态写到这里,
## player.gd 优先读取本单例,回退到键鼠(桌面端不受影响)。
## enabled 仅在触屏设备为 true,避免桌面端摇杆归零覆盖键鼠。

var enabled: bool = false

var move_vec: Vector2 = Vector2.ZERO      # 左摇杆:归一化前的原始向量(长度 0..1)
var aim_vec: Vector2 = Vector2.ZERO       # 右摇杆:瞄准方向(长度 0..1)
var firing: bool = false                  # 右摇杆是否推动 -> 自动开火

# 一次性动作(按钮按下,player 消费后清除)
var _dash_pressed: bool = false
var _melee_pressed: bool = false          # 保持按住状态
var _melee_held: bool = false
var _swap_pressed: bool = false
var _seasoning_pressed: bool = false

func _ready() -> void:
	# 移动端一律启用触屏(不依赖 is_touchscreen_available,部分安卓返回 false)
	enabled = OS.get_name() in ["Android", "iOS"]

func set_move(v: Vector2) -> void:
	move_vec = v

func set_aim(v: Vector2) -> void:
	aim_vec = v
	firing = v.length() > 0.25

func press_dash() -> void:
	_dash_pressed = true

func set_melee_held(held: bool) -> void:
	_melee_held = held
	if held:
		_melee_pressed = true

func press_swap() -> void:
	_swap_pressed = true

func press_seasoning() -> void:
	_seasoning_pressed = true

# --- player 消费接口 ---

func consume_dash() -> bool:
	var v := _dash_pressed
	_dash_pressed = false
	return v

func melee_held() -> bool:
	return _melee_held

func consume_swap() -> bool:
	var v := _swap_pressed
	_swap_pressed = false
	return v

func consume_seasoning() -> bool:
	var v := _seasoning_pressed
	_seasoning_pressed = false
	return v
