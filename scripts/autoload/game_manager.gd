extends Node
## 全局游戏流程状态机(任务 11.x)。
## MainMenu / Playing / Paused / Result 之间切换 + 场景跳转。

enum State { MAIN_MENU, PLAYING, PAUSED, RESULT }

const GAME_SCENE := "res://scenes/game.tscn"
const MENU_SCENE := "res://scenes/main_menu.tscn"
const RESULT_SCENE := "res://scenes/result.tscn"

var state: State = State.MAIN_MENU
var last_win: bool = false
var last_floor: int = 1
var last_tips: int = 0
# 暂停来源栈:事件 UI/剧情卡片等可叠加,关闭一个才恢复
var _pause_sources: Array[Node] = []
var _hitstop_id: int = 0

## 命中顿帧:短暂降低时间流速再恢复(不受暂停/时间缩放影响的真实计时)
func hitstop(scale: float, duration: float) -> void:
	if get_tree().paused:
		return
	_hitstop_id += 1
	var id := _hitstop_id
	Engine.time_scale = scale
	await get_tree().create_timer(duration, true, false, true).timeout
	if id == _hitstop_id:
		Engine.time_scale = 1.0

func set_state(new_state: State) -> void:
	state = new_state

func start_game() -> void:
	RunContext.reset_run()
	_apply_loadout()
	ProjectilePool.clear_all()
	Engine.time_scale = 1.0
	state = State.PLAYING
	get_tree().paused = false
	get_tree().change_scene_to_file(GAME_SCENE)

## 从存档读取玩家选定的开局武器,写入 RunContext(空/未解锁则用默认)
func _apply_loadout() -> void:
	var l := SaveSystem.get_loadout()
	var m := ContentDB.weapon_by_id(l.get("melee", ""))
	var r := ContentDB.weapon_by_id(l.get("ranged", ""))
	RunContext.starting_melee = m if m and ContentDB.is_weapon_available(m.id) else null
	RunContext.starting_ranged = r if r and ContentDB.is_weapon_available(r.id) else null

func game_over(win: bool) -> void:
	last_win = win
	last_floor = RunContext.current_floor
	last_tips = RunContext.tips
	state = State.RESULT
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file(RESULT_SCENE)

func to_main_menu() -> void:
	state = State.MAIN_MENU
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)

func toggle_pause() -> void:
	if state == State.PLAYING:
		state = State.PAUSED
		get_tree().paused = true
	elif state == State.PAUSED:
		state = State.PLAYING
		get_tree().paused = false

## 事件/剧情等追加暂停源;首个源触发暂停
func push_pause(source: Node) -> void:
	if source not in _pause_sources:
		_pause_sources.append(source)
	if not get_tree().paused:
		state = State.PAUSED
		get_tree().paused = true

## 关闭一个暂停源;栈空才恢复游戏
func pop_pause(source: Node) -> void:
	_pause_sources.erase(source)
	if _pause_sources.is_empty() and state == State.PAUSED:
		state = State.PLAYING
		get_tree().paused = false
