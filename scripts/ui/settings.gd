extends Control
## 通用设置面板:操作说明 + 音量 + 改键。主菜单齿轮/局内暂停均可打开。
## 覆盖全屏、拦截输入;process_mode=ALWAYS 使局内暂停时也能操作。

const OP_TEXT := "WASD移动 / 左键远程 / 右键近战 / 空格冲刺 / E调料 / F互动"

@onready var volume_slider: HSlider = $Panel/Vol/Slider
@onready var volume_label: Label = $Panel/Vol/Value
@onready var keys_box: VBoxContainer = $Panel/Keys

var _listening_action: String = ""
var _listening_btn: Button = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Panel/Ops.text = OP_TEXT
	$Panel/Close.pressed.connect(_close)
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.value = SaveSystem.get_volume()
	volume_slider.value_changed.connect(_on_volume)
	_update_vol_label(volume_slider.value)
	_build_key_rows()

func _on_volume(v: float) -> void:
	SaveSystem.set_volume(v)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(v, 0.0001)))
	_update_vol_label(v)

func _update_vol_label(v: float) -> void:
	volume_label.text = "%d%%" % int(round(v * 100.0))

func _build_key_rows() -> void:
	for action in InputSetup.REBINDABLE.keys():
		var row := HBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.text = InputSetup.REBINDABLE[action]
		name_lbl.custom_minimum_size = Vector2(120, 0)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(160, 0)
		btn.text = _key_name(action)
		btn.pressed.connect(_start_listen.bind(action, btn))
		row.add_child(name_lbl)
		row.add_child(btn)
		keys_box.add_child(row)

func _key_name(action: String) -> String:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			return OS.get_keycode_string((ev as InputEventKey).physical_keycode)
	return "?"

func _start_listen(action: String, btn: Button) -> void:
	if _listening_btn:
		_listening_btn.text = _key_name(_listening_action)
	_listening_action = action
	_listening_btn = btn
	btn.text = "按任意键…"

func _input(event: InputEvent) -> void:
	if _listening_action == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var code := (event as InputEventKey).physical_keycode
		if code == KEY_ESCAPE:
			# 取消改键,不关面板
			_listening_btn.text = _key_name(_listening_action)
		else:
			InputSetup.rebind_key(_listening_action, code)
			SaveSystem.set_key_override(_listening_action, code)
			_listening_btn.text = _key_name(_listening_action)
		_listening_action = ""
		_listening_btn = null
		accept_event()

func _close() -> void:
	queue_free()
