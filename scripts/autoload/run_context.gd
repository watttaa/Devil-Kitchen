extends Node
## 局内状态聚合(任务 9.x / 11.x)。Autoload 单例。
## 保存本局:小费、楼层、起手武器、食谱、调料、随机种子。
## 玩家死亡时 reset_run() 清空,实现永久死亡。

signal tips_changed(amount: int)
signal recipes_changed(recipes: Array)
signal seasonings_changed(seasonings: Dictionary)
signal synergy_activated(name: String)
signal floor_changed(floor: int)
signal combo_changed(count: int)

const FINAL_FLOOR := 3
const COMBO_WINDOW := 2.5

var rng := RandomNumberGenerator.new()
var tips: int = 0
var current_floor: int = 1
var combo: int = 0
var _combo_timer: float = 0.0

# 起手武器(可由 CharacterData 设置;null 时玩家用默认武器)
var starting_melee: WeaponData = null
var starting_ranged: WeaponData = null

# 局内构筑
var recipes: Array[RecipeData] = []
var seasonings: Dictionary = {}     # SeasoningData -> count
var active_synergies: Array[String] = []

# synergy 表:某 tag 持有数量达到 need 即触发
const SYNERGY_TABLE := [
	{"tag": "spicy", "need": 2, "name": "麻辣套餐", "damage_mult": 1.25},
	{"tag": "sweet", "need": 2, "name": "甜蜜暴击", "attack_speed_mult": 1.25},
	{"tag": "sour", "need": 2, "name": "酸爽连击", "move_speed_mult": 1.2, "attack_speed_mult": 1.1},
	{"tag": "hearty", "need": 2, "name": "饱腹强韧", "damage_mult": 1.1, "move_speed_mult": 1.1},
]

func _ready() -> void:
	rng.randomize()

func _process(delta: float) -> void:
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0 and combo != 0:
			combo = 0
			combo_changed.emit(0)

## 击杀登记:连击 +1 并刷新计时窗口
func register_kill() -> void:
	combo += 1
	_combo_timer = COMBO_WINDOW
	combo_changed.emit(combo)

## 连击伤害加成:每 1 连击 +2%,封顶 +40%(连击 20 达上限)
func combo_damage_mult() -> float:
	return 1.0 + clampf(float(combo), 0.0, 20.0) * 0.02

func reset_run() -> void:
	rng.randomize()
	tips = 0
	current_floor = 1
	combo = 0
	_combo_timer = 0.0
	recipes.clear()
	seasonings.clear()
	active_synergies.clear()
	tips_changed.emit(tips)
	recipes_changed.emit(recipes)
	seasonings_changed.emit(seasonings)
	floor_changed.emit(current_floor)
	combo_changed.emit(0)

func advance_floor() -> void:
	current_floor += 1
	floor_changed.emit(current_floor)

func is_final_floor() -> bool:
	return current_floor >= FINAL_FLOOR

# --- 小费 ---

func add_tips(n: int) -> void:
	tips += n
	tips_changed.emit(tips)

func spend_tips(n: int) -> bool:
	if tips >= n:
		tips -= n
		tips_changed.emit(tips)
		return true
	return false

# --- 食谱 ---

func add_recipe(r: RecipeData) -> void:
	recipes.append(r)
	recipes_changed.emit(recipes)
	_recompute_synergies()
	_apply_passives_to_player()

func _recompute_synergies() -> void:
	active_synergies.clear()
	for syn in SYNERGY_TABLE:
		var count := 0
		for r in recipes:
			if syn["tag"] in r.synergy_tags:
				count += 1
		if count >= syn["need"]:
			active_synergies.append(syn["name"])
			synergy_activated.emit(syn["name"])

func _apply_passives_to_player() -> void:
	var dmg := 1.0
	var atk := 1.0
	var spd := 1.0
	for r in recipes:
		dmg *= r.damage_mult
		atk *= r.attack_speed_mult
		spd *= r.move_speed_mult
	for syn in SYNERGY_TABLE:
		if syn["name"] in active_synergies:
			dmg *= syn.get("damage_mult", 1.0)
			atk *= syn.get("attack_speed_mult", 1.0)
			spd *= syn.get("move_speed_mult", 1.0)
	var p := _player()
	if p:
		p.bonus_damage_mult = dmg
		p.bonus_attack_speed_mult = atk
		p.bonus_move_speed_mult = spd

## 房间清空时调用:结算"清房回血"类食谱
func on_room_cleared() -> void:
	var heal := 0
	for r in recipes:
		heal += r.heal_on_room_clear
	if heal > 0:
		var p := _player()
		if p:
			p.health.heal(heal)

# --- 调料 ---

func add_seasoning(s: SeasoningData) -> void:
	seasonings[s] = int(seasonings.get(s, 0)) + 1
	seasonings_changed.emit(seasonings)

## 使用一份指定调料;成功返回 true
func use_seasoning(s: SeasoningData) -> bool:
	if int(seasonings.get(s, 0)) <= 0:
		return false
	seasonings[s] = int(seasonings[s]) - 1
	if seasonings[s] <= 0:
		seasonings.erase(s)
	seasonings_changed.emit(seasonings)
	_apply_seasoning_effect(s)
	return true

## 使用任意一份持有的调料(供快捷键),成功返回 true
func use_any_seasoning() -> bool:
	for s in seasonings.keys():
		return use_seasoning(s)
	return false

func _apply_seasoning_effect(s: SeasoningData) -> void:
	var p := _player()
	if p == null:
		return
	match s.effect:
		SeasoningData.Effect.HEAL:
			p.health.heal(s.magnitude)
		SeasoningData.Effect.DAMAGE_BUFF:
			p.apply_temp_damage_buff(s.magnitude, s.duration)
		SeasoningData.Effect.SLOW_ENEMIES:
			get_tree().call_group("enemies", "apply_slow", s.magnitude, s.duration)

func _player() -> Node:
	return get_tree().get_first_node_in_group("player")
