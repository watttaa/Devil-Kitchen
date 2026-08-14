extends Node
## 局外持久存档(扩张 1.1)。Autoload 单例 "SaveSystem"。
## user://save.json:版本号 + 累计统计 + 已解锁内容 id 集合。
## 与局内状态(RunContext)完全独立;局内每局清空,本存档跨会话持久。

const SAVE_PATH := "user://save.json"
const BACKUP_PATH := "user://save.bak.json"
const VERSION := 1

var data: Dictionary = {}

func _ready() -> void:
	_load()

func _default_data() -> Dictionary:
	return {
		"version": VERSION,
		"stats": {
			"runs": 0,
			"wins": 0,
			"kills": 0,
			"best_floor": 1,
		},
		"kills_by_enemy": {},   # 各怪种累计击杀:{ enemy_id: count }
		"unlocked": [],   # 已解锁内容 id
		"loadout": {"melee": "", "ranged": ""},   # 玩家选定的开局武器 id
		"settings": {"volume": 1.0, "keys": {}},  # 音量(0..1) + 键位覆盖 {action: keycode}
		"profile": _default_profile(),
	}

func _default_profile() -> Dictionary:
	return {
		"name": "可可",
		"body": [0.36, 0.72, 1.0],
		"hat": [1.0, 1.0, 1.0],
		"accent": [0.9, 0.3, 0.35],
		"accessory": 0,
	}

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		data = _default_data()
		_save()
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		data = _default_data()
		return
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		_backup_corrupt(text)
		data = _default_data()
		_save()
		return
	data = _migrate(parsed)
	_save()

func _migrate(d: Dictionary) -> Dictionary:
	# 合并默认字段,容忍缺失/旧版本
	var base := _default_data()
	for k in base.keys():
		if not d.has(k):
			d[k] = base[k]
	if typeof(d.get("stats")) != TYPE_DICTIONARY:
		d["stats"] = base["stats"]
	else:
		for sk in base["stats"].keys():
			if not d["stats"].has(sk):
				d["stats"][sk] = base["stats"][sk]
	if typeof(d.get("unlocked")) != TYPE_ARRAY:
		d["unlocked"] = []
	if typeof(d.get("kills_by_enemy")) != TYPE_DICTIONARY:
		d["kills_by_enemy"] = {}
	if typeof(d.get("loadout")) != TYPE_DICTIONARY:
		d["loadout"] = {"melee": "", "ranged": ""}
	if typeof(d.get("settings")) != TYPE_DICTIONARY:
		d["settings"] = {"volume": 1.0, "keys": {}}
	else:
		if not d["settings"].has("volume"):
			d["settings"]["volume"] = 1.0
		if typeof(d["settings"].get("keys")) != TYPE_DICTIONARY:
			d["settings"]["keys"] = {}
	if typeof(d.get("profile")) != TYPE_DICTIONARY:
		d["profile"] = _default_profile()
	else:
		for pk in base["profile"].keys():
			if not d["profile"].has(pk):
				d["profile"][pk] = base["profile"][pk]
	d["version"] = VERSION
	return d

func _backup_corrupt(text: String) -> void:
	var b := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
	if b:
		b.store_string(text)
		b.close()

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

# --- 统计 ---

func add_kill(n: int = 1, enemy_id: String = "") -> void:
	data["stats"]["kills"] = int(data["stats"]["kills"]) + n
	if enemy_id != "":
		var m: Dictionary = data["kills_by_enemy"]
		m[enemy_id] = int(m.get(enemy_id, 0)) + n
	_save()

func record_run_end(reached_floor: int, won: bool) -> void:
	data["stats"]["runs"] = int(data["stats"]["runs"]) + 1
	if won:
		data["stats"]["wins"] = int(data["stats"]["wins"]) + 1
	if reached_floor > int(data["stats"]["best_floor"]):
		data["stats"]["best_floor"] = reached_floor
	_save()

func stat(key: String) -> int:
	return int(data["stats"].get(key, 0))

func kills_of(enemy_id: String) -> int:
	return int(data["kills_by_enemy"].get(enemy_id, 0))

# --- 解锁 ---

func is_unlocked(id: String) -> bool:
	return id in data["unlocked"]

func unlock(id: String) -> bool:
	if id in data["unlocked"]:
		return false
	data["unlocked"].append(id)
	_save()
	return true

# --- 开局武器选择(持久化) ---

func get_loadout() -> Dictionary:
	if typeof(data.get("loadout")) != TYPE_DICTIONARY:
		data["loadout"] = {"melee": "", "ranged": ""}
	return data["loadout"]

func set_loadout_slot(is_melee: bool, weapon_id: String) -> void:
	var l := get_loadout()
	l["melee" if is_melee else "ranged"] = weapon_id
	_save()

# --- 设置(音量 + 键位) ---

func get_settings() -> Dictionary:
	if typeof(data.get("settings")) != TYPE_DICTIONARY:
		data["settings"] = {"volume": 1.0, "keys": {}}
	return data["settings"]

func get_volume() -> float:
	return float(get_settings().get("volume", 1.0))

func set_volume(v: float) -> void:
	get_settings()["volume"] = clampf(v, 0.0, 1.0)
	_save()

func get_key_overrides() -> Dictionary:
	var k = get_settings().get("keys", {})
	return k if typeof(k) == TYPE_DICTIONARY else {}

func set_key_override(action: String, keycode: int) -> void:
	get_settings()["keys"][action] = keycode
	_save()

# --- 角色形象 profile ---
func get_profile() -> Dictionary:
	if typeof(data.get("profile")) != TYPE_DICTIONARY:
		data["profile"] = _default_profile()
	return data["profile"]

func set_profile(p: Dictionary) -> void:
	data["profile"] = p
	_save()
