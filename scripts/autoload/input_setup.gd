extends Node
## 运行时注册所有输入动作(任务 1.3)。
## 用代码注册而非手写 project.godot 序列化,跨 Godot 版本稳定、不易出错。
## 作为 Autoload,会在主场景之前初始化,游戏逻辑读取这些动作时一定已存在。

func _ready() -> void:
	# 移动:WASD + 方向键
	_add_keys("move_up", [KEY_W, KEY_UP])
	_add_keys("move_down", [KEY_S, KEY_DOWN])
	_add_keys("move_left", [KEY_A, KEY_LEFT])
	_add_keys("move_right", [KEY_D, KEY_RIGHT])

	# 战斗:左键远程(twin-stick 主火力)、右键近战
	_add_mouse("ranged_attack", MOUSE_BUTTON_LEFT)
	_add_mouse("melee_attack", MOUSE_BUTTON_RIGHT)

	# 其它动作
	_add_keys("dash", [KEY_SPACE])
	_add_keys("switch_weapon", [KEY_Q])
	_add_keys("use_seasoning", [KEY_E])
	_add_keys("interact", [KEY_F])
	_add_keys("pause", [KEY_ESCAPE])

	_apply_settings()

## 可改键的动作(设置界面用)。名称 -> 中文标签。
const REBINDABLE := {
	"move_up": "上", "move_down": "下", "move_left": "左", "move_right": "右",
	"dash": "冲刺", "use_seasoning": "调料", "interact": "互动",
}

## 应用存档中的音量与键位覆盖
func _apply_settings() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(SaveSystem.get_volume(), 0.0001)))
	for action in SaveSystem.get_key_overrides().keys():
		if REBINDABLE.has(action):
			rebind_key(action, int(SaveSystem.get_key_overrides()[action]))

## 把某动作的键盘绑定改为单一 keycode(保留鼠标等其它事件)
func rebind_key(action: StringName, keycode: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			InputMap.action_erase_event(action, ev)
	var e := InputEventKey.new()
	e.physical_keycode = keycode
	InputMap.action_add_event(action, e)

func _add_keys(action: StringName, physical_keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in physical_keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)

func _add_mouse(action: StringName, button: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button as MouseButton
	InputMap.action_add_event(action, ev)
