extends CanvasLayer
class_name HUD
## 抬头显示(任务 8.x / 11.x):红心生命、小费、武器/弹药、Synergy、调料、小地图。

@onready var hearts: Label = $Root/TopLeft/Hearts
@onready var tips_label: Label = $Root/TopLeft/Tips
@onready var weapon_label: Label = $Root/BottomLeft/Weapon
@onready var synergy_label: Label = $Root/BottomLeft/Synergy
@onready var seasoning_label: Label = $Root/BottomLeft/Seasoning
@onready var minimap: HBoxContainer = $Root/Minimap
@onready var toast: Label = $Root/Toast
@onready var floor_label: Label = $Root/Floor
@onready var combo_label: Label = $Root/Combo
@onready var boss_bar: Control = $Root/BossBar
@onready var boss_name: Label = $Root/BossBar/Name
@onready var boss_fill: ColorRect = $Root/BossBar/Fill

var _player: Node = null
var _rooms: Array = []
var _boss_health: Health = null

func bind(player: Node) -> void:
	_player = player
	player.health.health_changed.connect(_on_health)
	player.weapon_changed.connect(_on_weapon)
	player.ammo_changed.connect(_on_ammo)
	RunContext.tips_changed.connect(_on_tips)
	RunContext.recipes_changed.connect(func(_r): _refresh_synergy())
	RunContext.synergy_activated.connect(func(_n): _refresh_synergy())
	RunContext.seasonings_changed.connect(_on_seasonings)
	RunContext.combo_changed.connect(_on_combo)
	_on_health(player.health.current, player.health.max_health)
	_on_tips(RunContext.tips)
	_on_weapon(_player.melee_weapon.display_name, _player.ranged_weapon.display_name)
	_on_ammo(_player.ranged_ammo, _player.ranged_weapon.magazine_size)
	_refresh_synergy()
	_on_seasonings(RunContext.seasonings)

func _on_combo(count: int) -> void:
	if count >= 2:
		combo_label.visible = true
		var pct := int(round((RunContext.combo_damage_mult() - 1.0) * 100.0))
		combo_label.text = "连击 x%d  伤害+%d%%" % [count, pct]
		combo_label.scale = Vector2(1.3, 1.3)
		var t := create_tween()
		t.tween_property(combo_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	else:
		combo_label.visible = false

## Boss 出场:绑定其 Health 显示顶部血条
func show_boss_bar(bname: String, hp: Health) -> void:
	_boss_health = hp
	boss_name.text = bname
	boss_bar.visible = true
	_update_boss_fill(hp.current, hp.max_health)
	hp.health_changed.connect(_update_boss_fill)
	hp.died.connect(hide_boss_bar)

func _update_boss_fill(current: float, maximum: float) -> void:
	var frac: float = clampf(current / maxf(maximum, 1.0), 0.0, 1.0)
	boss_fill.anchor_right = frac

func hide_boss_bar() -> void:
	boss_bar.visible = false
	_boss_health = null

func _on_health(current: float, maximum: float) -> void:
	var full := int(round(current))
	var total := int(round(maximum))
	var s := ""
	for i in total:
		s += "♥" if i < full else "♡"
	hearts.text = s

func _on_tips(amount: int) -> void:
	tips_label.text = "窝囊费 $%d" % amount

func _on_weapon(melee_name: String, ranged_name: String) -> void:
	weapon_label.text = "近[右键] %s   远[左键] %s" % [melee_name, ranged_name]

func _on_ammo(current: int, _maximum: int) -> void:
	if _player and _player.melee_weapon and _player.ranged_weapon:
		weapon_label.text = "近[右键] %s   远[左键] %s  弹%d" % [
			_player.melee_weapon.display_name, _player.ranged_weapon.display_name, current]

func _refresh_synergy() -> void:
	if RunContext.active_synergies.is_empty():
		synergy_label.text = "套餐: 无"
	else:
		synergy_label.text = "套餐: " + ", ".join(RunContext.active_synergies)

func _on_seasonings(seasonings: Dictionary) -> void:
	var total := 0
	for c in seasonings.values():
		total += int(c)
	seasoning_label.text = "调料[E] x%d" % total

## 剧情/提示横幅,显示后自动淡出
func show_toast(msg: String, dur: float = 3.0) -> void:
	toast.text = msg
	toast.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(dur)
	t.tween_property(toast, "modulate:a", 0.0, 0.8)

func set_floor(n: int) -> void:
	floor_label.text = "第 %d 层" % n

# --- 小地图 ---

func set_rooms(rooms: Array) -> void:
	_rooms = rooms
	for c in minimap.get_children():
		c.queue_free()
	for r in rooms:
		var cell := ColorRect.new()
		cell.custom_minimum_size = Vector2(28, 28)
		cell.color = _room_color(r.room_type)
		minimap.add_child(cell)

func _room_color(t: int) -> Color:
	match t:
		Room.Type.START: return Color(0.4, 0.7, 0.9)
		Room.Type.SHOP: return Color(0.9, 0.85, 0.3)
		Room.Type.TREASURE: return Color(0.7, 0.4, 0.9)
		Room.Type.BOSS: return Color(0.9, 0.2, 0.2)
		Room.Type.ELITE: return Color(0.85, 0.5, 0.15)
		Room.Type.GAMBLE: return Color(0.4, 0.85, 0.45)
		Room.Type.ALTAR: return Color(0.55, 0.4, 0.85)
		Room.Type.EVENT: return Color(0.5, 0.7, 0.75)
		_: return Color(0.5, 0.5, 0.55)

func highlight(index: int) -> void:
	var cells := minimap.get_children()
	for i in cells.size():
		var cell := cells[i] as ColorRect
		cell.color = _room_color(_rooms[i].room_type)
		if i == index:
			cell.color = cell.color.lightened(0.4)
