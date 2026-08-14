extends CanvasLayer
## 底部对话框 Overlay:说话人头像(框上方)+ 名字 + 文本页。点击/F 翻页,ESC 跳过。

signal finished

const CHEF := preload("res://scripts/effects/chef_visual.gd")

# 说话人 → ChefVisual 预设(人类角色)。阿澈用玩家自定义存档形象。
const HUMAN_PRESETS := {
	"chef": {"body": [0.32, 0.3, 0.36], "hat": [0.55, 0.12, 0.14], "accent": [0.9, 0.75, 0.2], "accessory": 1},
	"dessert": {"body": [0.95, 0.7, 0.78], "hat": [0.98, 0.85, 0.9], "accent": [0.85, 0.4, 0.55], "accessory": 4},
}
# 说话人 → 食材/物件贴图(怪物)
const CREATURE_TEX := {
	"tomato": "res://kenney_food-kit/Previews/tomato.png",
	"plate": "res://kenney_food-kit/Previews/plate.png",
}
const SPEAKER_NAMES := {
	"chef": "地狱大厨",
	"dessert": "甜点师",
	"tomato": "番茄怪",
	"plate": "洗碗池怪塔",
	"narrator": "",
}

@onready var title_label: Label = $Root/Box/Title
@onready var body_label: Label = $Root/Box/Body
@onready var hint_label: Label = $Root/Box/Hint
@onready var portrait_frame: Panel = $Root/PortraitFrame
@onready var portrait_host: Control = $Root/PortraitFrame/PortraitHost
@onready var name_label: Label = $Root/PortraitFrame/Name

var _lines: PackedStringArray = PackedStringArray()
var _speakers: PackedStringArray = PackedStringArray()
var _index: int = 0

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func present(data: NarrativeData) -> void:
	if data == null or data.lines.is_empty():
		# 内容缺失(常见于打包漏资源)——直接跳过,避免卡在空对话框
		visible = false
		finished.emit()
		return
	_lines = data.lines
	_speakers = data.speakers
	_index = 0
	title_label.text = data.title
	_show_page()
	visible = true
	GameManager.push_pause(self)

func _show_page() -> void:
	body_label.text = _lines[_index] if _index < _lines.size() else ""
	var spk := "narrator"
	if _index < _speakers.size() and _speakers[_index] != "":
		spk = _speakers[_index]
	_set_speaker(spk)
	hint_label.text = "点击屏幕 / 按 F 翻页(ESC 跳过)"

func _set_speaker(id: String) -> void:
	for c in portrait_host.get_children():
		c.queue_free()
	if id == "narrator":
		portrait_frame.visible = false
		return
	portrait_frame.visible = true
	name_label.text = _display_name(id)
	if id == "ache":
		var v: ChefVisual = CHEF.new()
		v.apply(SaveSystem.get_profile())
		v.position = Vector2(60, 96)
		v.scale = Vector2(2.4, 2.4)
		portrait_host.add_child(v)
	elif HUMAN_PRESETS.has(id):
		var v2: ChefVisual = CHEF.new()
		v2.apply(HUMAN_PRESETS[id])
		v2.position = Vector2(60, 96)
		v2.scale = Vector2(2.4, 2.4)
		portrait_host.add_child(v2)
	elif CREATURE_TEX.has(id):
		var s := Sprite2D.new()
		var tex: Texture2D = load(CREATURE_TEX[id])
		s.texture = tex
		var w: float = maxf(float(tex.get_width()), 1.0)
		s.scale = Vector2.ONE * (96.0 / w)
		s.position = Vector2(60, 62)
		portrait_host.add_child(s)

func _display_name(id: String) -> String:
	if id == "ache":
		return str(SaveSystem.get_profile().get("name", "可可"))
	return str(SPEAKER_NAMES.get(id, ""))

## 全局捕获点击/触摸/F 翻页(用 _input 避免被上层 UI 拦截)
func _input(e: InputEvent) -> void:
	if not visible:
		return
	var tapped: bool = false
	var mb := e as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		tapped = true
	var st := e as InputEventScreenTouch
	if st != null and st.pressed:
		tapped = true
	if tapped or e.is_action_pressed("interact"):
		_next()
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("pause"):
		_close()
		get_viewport().set_input_as_handled()

func _next() -> void:
	_index += 1
	if _index >= _lines.size():
		_close()
	else:
		_show_page()

func _close() -> void:
	visible = false
	GameManager.pop_pause(self)
	finished.emit()
