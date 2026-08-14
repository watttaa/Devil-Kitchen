extends Control
## 捧厨师(角色自定义):配色 + 配饰 + 名字,实时预览,存档持久化。

const CHEF := preload("res://scripts/effects/chef_visual.gd")

const BODY_PALETTE := [
	Color(0.36, 0.72, 1), Color(0.95, 0.4, 0.4), Color(0.45, 0.8, 0.5),
	Color(0.95, 0.8, 0.3), Color(0.7, 0.5, 0.9), Color(0.9, 0.55, 0.25),
	Color(0.3, 0.3, 0.36), Color(0.95, 0.95, 0.98)]
const HAT_PALETTE := [
	Color(1, 1, 1), Color(0.2, 0.2, 0.24), Color(0.95, 0.5, 0.5),
	Color(0.5, 0.8, 0.9), Color(0.95, 0.85, 0.4), Color(0.6, 0.85, 0.6)]
const ACCENT_PALETTE := [
	Color(0.9, 0.3, 0.35), Color(0.95, 0.8, 0.3), Color(0.4, 0.75, 0.95),
	Color(0.55, 0.4, 0.85), Color(0.2, 0.2, 0.24), Color(0.95, 0.95, 0.98)]
const ACC_NAMES := ["无", "墨镜", "胡子", "围巾", "领结"]

var _p: Dictionary = {}
var _preview: ChefVisual

@onready var _preview_box: Control = $Panel/V/Main/PreviewBox
@onready var _name_edit: LineEdit = $Panel/V/Main/Controls/NameRow/NameEdit

func _ready() -> void:
	_p = SaveSystem.get_profile().duplicate(true)
	_preview = CHEF.new()
	_preview.position = Vector2(100, 200)
	_preview.scale = Vector2(3.2, 3.2)
	_preview_box.add_child(_preview)
	_preview.apply(_p)
	_name_edit.text = str(_p.get("name", "可可"))
	_build_swatches($Panel/V/Main/Controls/BodyRow, BODY_PALETTE, "body")
	_build_swatches($Panel/V/Main/Controls/HatRow, HAT_PALETTE, "hat")
	_build_swatches($Panel/V/Main/Controls/AccentRow, ACCENT_PALETTE, "accent")
	_build_accessory()
	$Panel/V/Buttons/Save.pressed.connect(_on_save)
	$Panel/V/Buttons/Back.pressed.connect(_close)
	$Panel/V/Buttons/Back.grab_focus()

func _build_swatches(row: HBoxContainer, palette: Array, key: String) -> void:
	for c in row.get_children():
		c.queue_free()
	for col in palette:
		var sw := ColorRect.new()
		sw.custom_minimum_size = Vector2(30, 30)
		sw.color = col
		sw.mouse_filter = Control.MOUSE_FILTER_STOP
		sw.gui_input.connect(_on_swatch.bind(key, col))
		row.add_child(sw)

func _on_swatch(e: InputEvent, key: String, col: Color) -> void:
	if e is InputEventMouseButton and e.pressed:
		_p[key] = [col.r, col.g, col.b]
		_preview.apply(_p)

func _build_accessory() -> void:
	var row: HBoxContainer = $Panel/V/Main/Controls/AccRow
	for c in row.get_children():
		c.queue_free()
	for i in ACC_NAMES.size():
		var b := Button.new()
		b.text = ACC_NAMES[i]
		b.pressed.connect(_on_acc.bind(i))
		row.add_child(b)

func _on_acc(idx: int) -> void:
	_p["accessory"] = idx
	_preview.apply(_p)

func _on_save() -> void:
	var n := _name_edit.text.strip_edges()
	_p["name"] = n if n != "" else "可可"
	SaveSystem.set_profile(_p)
	_close()

func _close() -> void:
	queue_free()
