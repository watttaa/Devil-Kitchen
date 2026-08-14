extends Node
## 内容库(任务 9.x):集中管理可随机掉落/出售的内容资源。
## 由宝箱、商店、楼层生成器引用。Autoload 单例 "ContentDB"。

var weapons: Array[WeaponData] = [
	preload("res://resources/weapons/cleaver.tres"),
	preload("res://resources/weapons/pepper.tres"),
	preload("res://resources/weapons/pan.tres"),
	preload("res://resources/weapons/ladle.tres"),
	preload("res://resources/weapons/cleaver_heavy.tres"),
	preload("res://resources/weapons/spatula.tres"),
	preload("res://resources/weapons/fork.tres"),
	preload("res://resources/weapons/ketchup.tres"),
	preload("res://resources/weapons/oil.tres"),
	preload("res://resources/weapons/shield_pan.tres"),
	preload("res://resources/weapons/corn_gun.tres"),
	preload("res://resources/weapons/tomato_juice.tres"),
]

var recipes: Array[RecipeData] = [
	preload("res://resources/recipes/salt.tres"),
	preload("res://resources/recipes/chili_oil.tres"),
	preload("res://resources/recipes/pepper_recipe.tres"),
	preload("res://resources/recipes/honey.tres"),
	preload("res://resources/recipes/sugar.tres"),
	preload("res://resources/recipes/nutrition.tres"),
	preload("res://resources/recipes/vinegar.tres"),
	preload("res://resources/recipes/lemon_recipe.tres"),
	preload("res://resources/recipes/steak.tres"),
	preload("res://resources/recipes/stew.tres"),
	preload("res://resources/recipes/wasabi.tres"),
	preload("res://resources/recipes/chocolate.tres"),
	preload("res://resources/recipes/honey_glaze.tres"),
	preload("res://resources/recipes/pickle.tres"),
	preload("res://resources/recipes/roast.tres"),
	preload("res://resources/recipes/caramel.tres"),
]

var seasonings: Array[SeasoningData] = [
	preload("res://resources/seasonings/lemon.tres"),
	preload("res://resources/seasonings/hot_sauce.tres"),
	preload("res://resources/seasonings/honey_glue.tres"),
	preload("res://resources/seasonings/soy_sauce.tres"),
	preload("res://resources/seasonings/mustard.tres"),
	preload("res://resources/seasonings/ice_cube.tres"),
]

var enemies: Array[EnemyData] = [
	preload("res://resources/enemies/tomato.tres"),
	preload("res://resources/enemies/broccoli.tres"),
	preload("res://resources/enemies/chili.tres"),
	preload("res://resources/enemies/carrot.tres"),
	preload("res://resources/enemies/eggplant.tres"),
	preload("res://resources/enemies/corn.tres"),
	preload("res://resources/enemies/beet.tres"),
]

## 默认锁定的内容 id(需解锁后才进入随机池)。
const LOCKED_BY_DEFAULT: Array[String] = [
	"oil",
	"shield_pan",
	"cleaver_heavy",
	"corn_gun",
	"tomato_juice",
]

const UNLOCK_CONDITIONS: Array[UnlockData] = [
	preload("res://resources/unlocks/unlock_oil.tres"),
	preload("res://resources/unlocks/unlock_shield_pan.tres"),
	preload("res://resources/unlocks/unlock_cleaver_heavy.tres"),
	preload("res://resources/unlocks/unlock_corn_gun.tres"),
	preload("res://resources/unlocks/unlock_tomato_juice.tres"),
]

## 结算时调用:检查所有未解锁项,满足条件则解锁
func check_unlocks() -> Array[String]:
	var newly: Array[String] = []
	for u in UNLOCK_CONDITIONS:
		if SaveSystem.is_unlocked(u.target_content):
			continue
		var ok := false
		match u.condition:
			UnlockData.Cond.STAT_KILLS:
				ok = SaveSystem.stat("kills") >= u.threshold
			UnlockData.Cond.STAT_WINS:
				ok = SaveSystem.stat("wins") >= u.threshold
			UnlockData.Cond.STAT_BEST_FLOOR:
				ok = SaveSystem.stat("best_floor") >= u.threshold
			UnlockData.Cond.KILLS_ENEMY:
				ok = SaveSystem.kills_of(u.enemy_id) >= u.threshold
		if ok:
			SaveSystem.unlock(u.target_content)
			newly.append(u.display_name)
	return newly

func _available(arr: Array) -> Array:
	var out: Array = []
	for item in arr:
		var id: String = item.id if "id" in item else ""
		if id in LOCKED_BY_DEFAULT and not SaveSystem.is_unlocked(id):
			continue
		out.append(item)
	return out

func _pick(arr: Array):
	var pool := _available(arr)
	if pool.is_empty():
		pool = arr
	return pool[RunContext.rng.randi() % pool.size()]

func random_weapon() -> WeaponData:
	return _pick(weapons)

## 玩家已解锁(默认可用或已达成条件)的武器,按类型过滤
func unlocked_weapons_of(weapon_type: int) -> Array[WeaponData]:
	var out: Array[WeaponData] = []
	for w in weapons:
		if w.type != weapon_type:
			continue
		if w.id in LOCKED_BY_DEFAULT and not SaveSystem.is_unlocked(w.id):
			continue
		out.append(w)
	return out

## 反查某武器的解锁条件(无则返回 null,表示默认可用)
func unlock_of(weapon_id: String) -> UnlockData:
	for u in UNLOCK_CONDITIONS:
		if u.target_content == weapon_id:
			return u
	return null

func is_weapon_available(weapon_id: String) -> bool:
	return not (weapon_id in LOCKED_BY_DEFAULT) or SaveSystem.is_unlocked(weapon_id)

## 按 id 查武器,找不到返回 null
func weapon_by_id(weapon_id: String) -> WeaponData:
	if weapon_id == "":
		return null
	for w in weapons:
		if w.id == weapon_id:
			return w
	return null

func random_recipe() -> RecipeData:
	return _pick(recipes)

func random_seasoning() -> SeasoningData:
	return _pick(seasonings)

func random_enemy() -> EnemyData:
	return _pick(enemies)
