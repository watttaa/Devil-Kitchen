extends Node2D
## 对局主控(任务 11.x):生成楼层、放置玩家、挂 HUD、处理暂停/死亡/通关。

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const HUD_SCENE := preload("res://scenes/hud.tscn")
const NARRATIVE_UI_SCENE := preload("res://scenes/narrative_ui.tscn")

const FLOOR_NARRATIVE := {
	1: preload("res://resources/narrative/floor1_enter.tres"),
	2: preload("res://resources/narrative/floor2_enter.tres"),
	3: preload("res://resources/narrative/floor3_enter.tres"),
}
const BOSS_BEFORE_NARRATIVE := {
	1: preload("res://resources/narrative/boss1_before.tres"),
	2: preload("res://resources/narrative/boss2_before.tres"),
	3: preload("res://resources/narrative/boss3_before.tres"),
}
const BOSS_AFTER_NARRATIVE := {
	1: preload("res://resources/narrative/boss1_after.tres"),
	2: preload("res://resources/narrative/boss2_after.tres"),
}
const FINAL_NARRATIVE := preload("res://resources/narrative/boss3_after.tres")

var _gen := FloorGenerator.new()
var _player: Node2D
var _hud: HUD
var _narrative_ui: CanvasLayer
var _narrated_floor: int = 0

@onready var world: Node2D = $World
@onready var pause_menu: CanvasLayer = $PauseMenu

func _ready() -> void:
	GameManager.state = GameManager.State.PLAYING
	get_tree().paused = false
	pause_menu.visible = false
	$DebugBar/Box/KillAll.pressed.connect(_debug_kill_room)
	$DebugBar/Box/God.pressed.connect(_debug_toggle_god)
	$DebugBar/Box/Skip.pressed.connect(_debug_skip_floor)
	var resume_btn := pause_menu.get_node_or_null("Panel/Resume")
	var settings_btn := pause_menu.get_node_or_null("Panel/Settings")
	var quit_btn := pause_menu.get_node_or_null("Panel/Quit")
	if resume_btn:
		resume_btn.pressed.connect(_toggle_pause)
	if settings_btn:
		settings_btn.pressed.connect(_open_settings)
	if quit_btn:
		quit_btn.pressed.connect(GameManager.to_main_menu)
	_start_floor()

const SETTINGS_SCENE := preload("res://scenes/settings.tscn")

func _open_settings() -> void:
	pause_menu.add_child(SETTINGS_SCENE.instantiate())

func _start_floor() -> void:
	for c in world.get_children():
		c.queue_free()
	await get_tree().process_frame  # 等旧节点释放
	ProjectilePool.clear_all()

	var start_pos := _gen.generate(world, RunContext.current_floor)

	if _player == null or not is_instance_valid(_player):
		_player = PLAYER_SCENE.instantiate()
		world.add_child(_player)
		_player.global_position = start_pos
		_player.health.died.connect(_on_player_died)
	else:
		_player.global_position = start_pos

	if _hud == null:
		_hud = HUD_SCENE.instantiate()
		add_child(_hud)
		_hud.bind(_player)
	_hud.set_rooms(_gen.rooms)
	_hud.set_floor(RunContext.current_floor)
	_hud.show_toast("第 %d 层 · 杀穿餐厅,直捣地狱大厨!" % RunContext.current_floor)

	var boss_room: Room = _gen.rooms.back()
	if boss_room.boss_defeated.is_connected(_on_boss_defeated):
		boss_room.boss_defeated.disconnect(_on_boss_defeated)
	boss_room.boss_defeated.connect(_on_boss_defeated)
	if boss_room.boss_started.is_connected(_on_boss_started):
		boss_room.boss_started.disconnect(_on_boss_started)
	boss_room.boss_started.connect(_on_boss_started)

	# 进入楼层叙事(仅首次进入该层)
	if _narrated_floor != RunContext.current_floor:
		_narrated_floor = RunContext.current_floor
		if FLOOR_NARRATIVE.has(RunContext.current_floor):
			_show_narrative(FLOOR_NARRATIVE[RunContext.current_floor])

func _show_narrative(data: NarrativeData) -> void:
	if _narrative_ui == null or not is_instance_valid(_narrative_ui):
		_narrative_ui = NARRATIVE_UI_SCENE.instantiate()
		add_child(_narrative_ui)
	_narrative_ui.present(data)

func _process(_d: float) -> void:
	if _player and is_instance_valid(_player) and _hud:
		_hud.highlight(_gen.current_index(_player.global_position.x))

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("pause"):
		_toggle_pause()
	elif e is InputEventKey and e.pressed and not e.echo:
		match e.physical_keycode:
			KEY_K: _debug_kill_room()
			KEY_G: _debug_toggle_god()
			KEY_J: _debug_skip_floor()

# --- 测试工具 ---

func _debug_kill_room() -> void:
	var n := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.has_node("Health"):
			e.get_node("Health").take_damage(999999.0)
			n += 1
	if _hud:
		_hud.show_toast("[测试] 清空 %d 只怪" % n, 1.5)

func _debug_toggle_god() -> void:
	if _player and is_instance_valid(_player):
		_player.debug_god = not _player.debug_god
		if _hud:
			_hud.show_toast("[测试] 无敌:%s" % ("开" if _player.debug_god else "关"), 1.5)

func _debug_skip_floor() -> void:
	if _hud:
		_hud.show_toast("[测试] 跳过本层", 1.2)
	_on_boss_defeated()

func _toggle_pause() -> void:
	GameManager.toggle_pause()
	pause_menu.visible = (GameManager.state == GameManager.State.PAUSED)

func _on_player_died() -> void:
	SaveSystem.record_run_end(RunContext.current_floor, false)
	GameManager.game_over(false)

func _on_boss_defeated() -> void:
	if RunContext.is_final_floor():
		_show_narrative(FINAL_NARRATIVE)
		await _narrative_ui.finished
		SaveSystem.record_run_end(RunContext.current_floor, true)
		GameManager.game_over(true)
	else:
		if BOSS_AFTER_NARRATIVE.has(RunContext.current_floor):
			_show_narrative(BOSS_AFTER_NARRATIVE[RunContext.current_floor])
			await _narrative_ui.finished
		RunContext.advance_floor()
		_start_floor()

func _on_boss_started() -> void:
	_hud.show_toast("「地狱大厨」现身了!")
	var boss := get_tree().get_first_node_in_group("boss")
	if boss and _hud:
		_hud.show_boss_bar("地狱大厨 · 第 %d 灶" % RunContext.current_floor, boss.health)
	if BOSS_BEFORE_NARRATIVE.has(RunContext.current_floor):
		_show_narrative(BOSS_BEFORE_NARRATIVE[RunContext.current_floor])
