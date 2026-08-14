extends Node2D
class_name Room
## 房间控制器(任务 6.x):状态机 进入→(战斗:锁门生怪)→清空→开门。
## 非战斗房(起点/商店/宝箱)进入即布置内容、门常开。
## 由楼层生成器设置 room_type / has_left_door / has_right_door / 内容。

signal room_cleared(room)
signal boss_defeated
signal boss_started

enum Type { START, COMBAT, SHOP, TREASURE, BOSS, ELITE, GAMBLE, ALTAR, EVENT }
enum State { UNENTERED, ACTIVE, CLEARED }

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const PICKUP_SCENE := preload("res://scenes/pickup.tscn")
const WEAPON_PICKUP_SCENE := preload("res://scenes/weapon_pickup.tscn")
const SHOP_ITEM_SCENE := preload("res://scenes/shop_item.tscn")
const BOSS_SCENE := preload("res://scenes/boss.tscn")
const EVENT_UI_SCENE := preload("res://scenes/event_ui.tscn")

const ELITE_POOL: Array[EnemyData] = [
	preload("res://resources/enemies/chili_elite.tres"),
	preload("res://resources/enemies/broccoli_elite.tres"),
]

# 事件池(扩张 3.x):事件房/祭坛房随机抽取
const EVENT_POOL: Array[EventData] = [
	preload("res://resources/events/mystery_potion.tres"),
	preload("res://resources/events/devils_bargain.tres"),
	preload("res://resources/events/spice_offer.tres"),
]

@export var room_type: Type = Type.COMBAT
var has_left_door := true
var has_right_door := true
var index := 0
var spawn_count := 4

var state := State.UNENTERED
var _alive := 0

@onready var room_area: Area2D = $RoomArea
@onready var door_left: RoomDoor = $DoorLeft
@onready var door_right: RoomDoor = $DoorRight
@onready var spawns: Node = $Spawns
@onready var anchor: Marker2D = $ContentAnchor
@onready var floor_node: KitchenFloor = $Floor

func _ready() -> void:
	room_area.body_entered.connect(_on_body_entered)
	_tint_floor()
	# 无门一侧永久封死,有门一侧初始开启
	door_left.open_door() if has_left_door else door_left.seal()
	door_right.open_door() if has_right_door else door_right.seal()

func _tint_floor() -> void:
	match room_type:
		Type.START:
			floor_node.set_base(Color(0.18, 0.26, 0.28))
		Type.SHOP:
			floor_node.set_base(Color(0.3, 0.25, 0.14))
		Type.TREASURE:
			floor_node.set_base(Color(0.26, 0.18, 0.31))
		Type.BOSS:
			floor_node.set_base(Color(0.32, 0.13, 0.15))
		Type.ELITE:
			floor_node.set_base(Color(0.28, 0.18, 0.1))
		Type.GAMBLE:
			floor_node.set_base(Color(0.15, 0.22, 0.16))
		Type.ALTAR:
			floor_node.set_base(Color(0.22, 0.16, 0.28))
		Type.EVENT:
			floor_node.set_base(Color(0.2, 0.22, 0.26))
		_:
			floor_node.set_base(Color(0.2, 0.21, 0.24))

func _lock_doors() -> void:
	if has_left_door: door_left.lock()
	if has_right_door: door_right.lock()

func _unlock_doors() -> void:
	if has_left_door: door_left.open_door()
	if has_right_door: door_right.open_door()

func _on_body_entered(body: Node) -> void:
	if state != State.UNENTERED or not body.is_in_group("player"):
		return
	state = State.ACTIVE
	# 延迟激活:避免在物理查询回调中改 Area 的 monitoring 状态而报错
	_activate.call_deferred()

func _activate() -> void:
	match room_type:
		Type.COMBAT:
			_lock_doors()
			_spawn_enemies()
		Type.ELITE:
			_lock_doors()
			_spawn_elite()
		Type.BOSS:
			_lock_doors()
			_spawn_boss()
		Type.SHOP:
			_populate_shop()
			state = State.CLEARED
		Type.TREASURE:
			_populate_treasure()
			state = State.CLEARED
		Type.GAMBLE:
			_populate_gamble()
			state = State.CLEARED
		Type.ALTAR:
			_present_event()
			state = State.CLEARED
		Type.EVENT:
			_present_event()
			state = State.CLEARED
		Type.START:
			state = State.CLEARED

# --- 战斗 ---

func _spawn_enemies() -> void:
	var points := spawns.get_children()
	var n: int = min(spawn_count, points.size())
	for i in n:
		var e := ENEMY_SCENE.instantiate()
		e.data = ContentDB.random_enemy()
		add_child(e)
		e.global_position = (points[i] as Node2D).global_position
		e.defeated.connect(_on_enemy_defeated)
		_alive += 1
	if _alive == 0:
		_clear()

func _spawn_boss() -> void:
	var boss := BOSS_SCENE.instantiate()
	add_child(boss)
	boss.global_position = anchor.global_position
	boss.defeated.connect(_on_enemy_defeated)
	_alive = 1
	boss_started.emit()

func _spawn_elite() -> void:
	var points := spawns.get_children()
	var n: int = mini(2, points.size())   # 精英房少而强
	for i in n:
		var e := ENEMY_SCENE.instantiate()
		e.data = ELITE_POOL[RunContext.rng.randi() % ELITE_POOL.size()]
		add_child(e)
		e.global_position = (points[i] as Node2D).global_position
		e.defeated.connect(_on_enemy_defeated)
		_alive += 1
	if _alive == 0:
		_clear()

# --- 非战斗内容 ---

func _populate_gamble() -> void:
	# 赌博:一个可交互的赌博台,支付小费换随机产出
	var item := SHOP_ITEM_SCENE.instantiate()
	item.item_kind = "gamble"
	item.price = 10
	add_child(item)
	item.global_position = anchor.global_position

func _present_event() -> void:
	var pool: Array[EventData] = EVENT_POOL
	if pool.is_empty():
		return
	var event := pool[RunContext.rng.randi() % pool.size()]
	var ui := EVENT_UI_SCENE.instantiate()
	get_tree().current_scene.add_child(ui)
	ui.option_chosen.connect(ui.execute)
	ui.present(event)

func _on_enemy_defeated() -> void:
	_alive -= 1
	if _alive <= 0:
		_clear()

func _clear() -> void:
	state = State.CLEARED
	_unlock_doors()
	RunContext.on_room_cleared()
	# 精英房清空额外奖励:小费 + 随机食谱
	if room_type == Type.ELITE:
		RunContext.add_tips(8)
		var rp := PICKUP_SCENE.instantiate()
		rp.kind = Pickup.Kind.RECIPE
		rp.recipe = ContentDB.random_recipe()
		add_child(rp)
		rp.global_position = anchor.global_position
	if room_type == Type.BOSS:
		boss_defeated.emit()
	room_cleared.emit(self)

# --- 非战斗内容 ---

func _populate_treasure() -> void:
	var wp := WEAPON_PICKUP_SCENE.instantiate()
	wp.weapon_data = ContentDB.random_weapon()
	add_child(wp)
	wp.global_position = anchor.global_position + Vector2(-90, 0)

	var rp := PICKUP_SCENE.instantiate()
	rp.kind = Pickup.Kind.RECIPE
	rp.recipe = ContentDB.random_recipe()
	add_child(rp)
	rp.global_position = anchor.global_position + Vector2(90, 0)

func _populate_shop() -> void:
	var offsets := [Vector2(-180, 0), Vector2(0, 0), Vector2(180, 0)]
	# 1 食谱 + 1 调料 + 1 回血
	_add_shop_item(offsets[0], "recipe", 15)
	_add_shop_item(offsets[1], "seasoning", 10)
	_add_shop_item(offsets[2], "heal", 8)

func _add_shop_item(offset: Vector2, kind: String, price: int) -> void:
	var item := SHOP_ITEM_SCENE.instantiate()
	item.item_kind = kind
	item.price = price
	match kind:
		"recipe":
			item.recipe = ContentDB.random_recipe()
		"seasoning":
			item.seasoning = ContentDB.random_seasoning()
	add_child(item)
	item.global_position = anchor.global_position + offset
