extends Node
class_name FloorGenerator
## 单层线性生成(任务 7.x):起点→战斗→宝箱→战斗→商店→战斗→Boss。
## 房间排成一行,相邻共用门洞;清怪开门后向右推进。

const ROOM_SCENE := preload("res://scenes/room.tscn")
const ROOM_SPACING := 1100.0

var rooms: Array = []

func generate(parent: Node, floor_num: int) -> Vector2:
	rooms.clear()
	var layout := _layout()
	for i in layout.size():
		var r: Room = ROOM_SCENE.instantiate()
		r.room_type = layout[i]
		r.index = i
		r.has_left_door = i > 0
		r.has_right_door = i < layout.size() - 1
		r.spawn_count = 3 + floor_num
		parent.add_child(r)
		r.position = Vector2(i * ROOM_SPACING, 0)
		rooms.append(r)
	return rooms[0].global_position

func clear() -> void:
	for r in rooms:
		if is_instance_valid(r):
			r.queue_free()
	rooms.clear()

func _layout() -> Array:
	# 第 1 层保持简单,高层注入精英/事件/赌博/祭坛
	var base := [
		Room.Type.START,
		Room.Type.COMBAT,
		Room.Type.TREASURE,
		Room.Type.COMBAT,
		Room.Type.SHOP,
		Room.Type.COMBAT,
		Room.Type.BOSS,
	]
	if RunContext.current_floor >= 2:
		base.insert(3, Room.Type.ELITE)
		base.insert(5, Room.Type.EVENT)
	if RunContext.current_floor >= 3:
		base.insert(2, Room.Type.GAMBLE)
		base.insert(7, Room.Type.ALTAR)
	return base

func current_index(player_x: float) -> int:
	return clampi(int(round(player_x / ROOM_SPACING)), 0, rooms.size() - 1)
