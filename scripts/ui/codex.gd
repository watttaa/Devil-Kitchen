extends Control
## 武器图鉴 + 装备选择:列出全部武器,已解锁可点选(近战/远程各一),未解锁显示条件进度。
## 选中即写入存档 loadout,持久跨会话。开始游戏时由 GameManager 读取,无需再开本界面。

@onready var list: VBoxContainer = $Panel/Scroll/List
@onready var stats: Label = $Panel/Stats

var _melee: WeaponData = null
var _ranged: WeaponData = null
var _rows: Array = []   # {btn, weapon}

func _ready() -> void:
	$Panel/Close.pressed.connect(_close)
	_load_saved()
	for w in ContentDB.weapons:
		_add_row(w)
	_refresh_stats()
	_refresh_selection()

func _load_saved() -> void:
	var l := SaveSystem.get_loadout()
	_melee = ContentDB.weapon_by_id(l.get("melee", ""))
	_ranged = ContentDB.weapon_by_id(l.get("ranged", ""))

func _add_row(w: WeaponData) -> void:
	var avail := ContentDB.is_weapon_available(w.id)
	var b := Button.new()
	b.toggle_mode = true
	b.disabled = not avail
	if avail:
		var tag := "近战" if w.type == WeaponData.Type.MELEE else "远程"
		b.text = "[%s] %s" % [tag, w.display_name]
		b.pressed.connect(_on_pick.bind(w))
	else:
		var u := ContentDB.unlock_of(w.id)
		if u:
			b.text = "🔒 %s  —  %s (%d/%d)" % [
				w.display_name, u.hint, _progress(u), u.threshold]
		else:
			b.text = "🔒 %s" % w.display_name
		b.modulate = Color(0.6, 0.6, 0.6)
	list.add_child(b)
	_rows.append({"btn": b, "weapon": w})

func _on_pick(w: WeaponData) -> void:
	var is_melee := w.type == WeaponData.Type.MELEE
	if is_melee:
		_melee = w
	else:
		_ranged = w
	SaveSystem.set_loadout_slot(is_melee, w.id)
	_refresh_selection()

func _refresh_selection() -> void:
	for r in _rows:
		var w: WeaponData = r["weapon"]
		r["btn"].button_pressed = w == _melee or w == _ranged
	var m := _melee.display_name if _melee else "默认"
	var rg := _ranged.display_name if _ranged else "默认"
	$Panel/Title.text = "武器图鉴   近战:%s  远程:%s" % [m, rg]

func _refresh_stats() -> void:
	stats.text = "累计: 局数 %d / 通关 %d / 最高层 %d / 击杀 %d" % [
		SaveSystem.stat("runs"), SaveSystem.stat("wins"),
		SaveSystem.stat("best_floor"), SaveSystem.stat("kills")]

func _progress(u: UnlockData) -> int:
	match u.condition:
		UnlockData.Cond.STAT_KILLS:
			return mini(SaveSystem.stat("kills"), u.threshold)
		UnlockData.Cond.STAT_WINS:
			return mini(SaveSystem.stat("wins"), u.threshold)
		UnlockData.Cond.STAT_BEST_FLOOR:
			return mini(SaveSystem.stat("best_floor"), u.threshold)
		UnlockData.Cond.KILLS_ENEMY:
			return mini(SaveSystem.kills_of(u.enemy_id), u.threshold)
	return 0

func _close() -> void:
	queue_free()
