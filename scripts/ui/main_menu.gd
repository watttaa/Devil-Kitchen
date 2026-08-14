extends Control
## 主菜单(任务 11.x + 自定义角色)。

const CODEX_SCENE := preload("res://scenes/codex.tscn")
const CREATOR_SCENE := preload("res://scenes/character_creator.tscn")
const SETTINGS_SCENE := preload("res://scenes/settings.tscn")
const CHEF := preload("res://scripts/effects/chef_visual.gd")

var _chef: ChefVisual
var _story_tpl: String = ""

func _ready() -> void:
	GameManager.state = GameManager.State.MAIN_MENU
	_story_tpl = $Panel/Story.text
	$Panel/Start.pressed.connect(GameManager.start_game)
	$Panel/Customize.pressed.connect(_open_creator)
	$Panel/Codex.pressed.connect(_open_codex)
	$Panel/Quit.pressed.connect(get_tree().quit)
	$SettingsBtn.pressed.connect(_open_settings)
	$Panel/Start.grab_focus()
	_chef = CHEF.new()
	$ChefStage/Pedestal.add_child(_chef)
	_refresh_chef()

func _open_settings() -> void:
	add_child(SETTINGS_SCENE.instantiate())

func _refresh_chef() -> void:
	_chef.apply(SaveSystem.get_profile())
	var pname := str(SaveSystem.get_profile().get("name", "可可"))
	$Panel/Greeting.text = "厨师 %s,准备好开工了吗?" % pname
	$Panel/Story.text = _story_tpl.replace("{name}", pname)

func _open_creator() -> void:
	var c := CREATOR_SCENE.instantiate()
	add_child(c)
	c.tree_exited.connect(_refresh_chef)

func _open_codex() -> void:
	var c := CODEX_SCENE.instantiate()
	add_child(c)
