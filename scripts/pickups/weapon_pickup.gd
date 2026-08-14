extends Area2D
class_name WeaponPickup
## 武器拾取替换(任务 4.2):玩家重叠时按 [F] 拾取,旧武器留在原地。
## 远程武器保留各自剩余弹药。

@export var weapon_data: WeaponData
@export var ammo: int = -1   # -1 表示满弹匣

@onready var vis: Sprite2D = $Vis
@onready var label: Label = $Label

var _player_in: Node = null

func _ready() -> void:
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	_refresh()

func _refresh() -> void:
	if weapon_data:
		if weapon_data.texture:
			vis.texture = weapon_data.texture
			var w: float = maxi(weapon_data.texture.get_width(), 1)
			vis.scale = Vector2.ONE * (40.0 / w)
		else:
			vis.modulate = weapon_data.color
		var tag := "近" if weapon_data.type == WeaponData.Type.MELEE else "远"
		label.text = "[" + tag + "] " + weapon_data.display_name + "\n按 F"

func _on_enter(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in = body

func _on_exit(body: Node) -> void:
	if body == _player_in:
		_player_in = null

func _process(_delta: float) -> void:
	if _player_in and weapon_data and Input.is_action_just_pressed("interact"):
		_swap()

func _swap() -> void:
	var p := _player_in
	if weapon_data.type == WeaponData.Type.MELEE:
		var old: WeaponData = p.set_melee_weapon(weapon_data)
		weapon_data = old
		ammo = -1
	else:
		var prev_ammo: int = p.ranged_ammo
		var give: int = ammo if ammo >= 0 else weapon_data.magazine_size
		var old: WeaponData = p.set_ranged_weapon(weapon_data, give)
		weapon_data = old
		ammo = prev_ammo
	_refresh()
