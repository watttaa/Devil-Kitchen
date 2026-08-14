extends Area2D
class_name ShopItem
## 商店商品(任务 8.x):玩家重叠时按 F 购买,扣除小费后发放内容。

@export var item_kind: String = "recipe"   # recipe / seasoning / heal
@export var price: int = 10
@export var recipe: RecipeData
@export var seasoning: SeasoningData

const GAMBLE_UI := preload("res://scenes/gamble_ui.tscn")

var _player: Node = null
var _sold := false
var _gamble_open := false

@onready var vis: Sprite2D = $Vis
@onready var label: Label = $Label

const TEX := {
	"recipe": "res://kenney_food-kit/Previews/salad.png",
	"seasoning": "res://kenney_food-kit/Previews/shaker-salt.png",
	"heal": "res://kenney_food-kit/Previews/lemon.png",
	"gamble": "res://kenney_food-kit/Previews/cake.png",
}

func _ready() -> void:
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	_refresh()

func _refresh() -> void:
	var item_name := ""
	match item_kind:
		"recipe":
			item_name = recipe.display_name if recipe else "食谱"
		"seasoning":
			item_name = seasoning.display_name if seasoning else "调料"
		"heal":
			item_name = "柠檬(回血)"
		"gamble":
			item_name = "幸运老虎机"
	var path: String = TEX.get(item_kind, TEX["recipe"])
	var tex: Texture2D = load(path)
	if tex:
		vis.texture = tex
		var w: float = maxi(tex.get_width(), 1)
		vis.scale = Vector2.ONE * (40.0 / w)
	if item_kind == "gamble":
		label.text = "%s\n每抽 $%d  按F" % [item_name, price]
	else:
		label.text = "%s\n$%d  按F" % [item_name, price]

func _on_enter(b: Node) -> void:
	if b.is_in_group("player"):
		_player = b

func _on_exit(b: Node) -> void:
	if b == _player:
		_player = null

func _process(_d: float) -> void:
	if _sold or _gamble_open or _player == null:
		return
	if Input.is_action_just_pressed("interact") or TouchInput.interact_just_pressed():
		_buy()

func _buy() -> void:
	if item_kind == "gamble":
		_open_gamble()
		return
	if not RunContext.spend_tips(price):
		label.text = "窝囊费不足!"
		return
	match item_kind:
		"recipe":
			if recipe:
				RunContext.add_recipe(recipe)
				_show_effect("%s:%s" % [recipe.display_name, recipe.description])
		"seasoning":
			if seasoning:
				RunContext.add_seasoning(seasoning)
				_show_effect("%s:%s" % [seasoning.display_name, seasoning.description])
		"heal":
			_player.health.heal(2)
			_show_effect("柠檬:立即回复 2 半心")
	_sold = true
	label.text = "已售出"
	vis.modulate = Color(0.4, 0.4, 0.4)

func _show_effect(msg: String) -> void:
	var hud := get_tree().current_scene.get_node_or_null("HUD")
	if hud and hud.has_method("show_toast"):
		hud.show_toast(msg, 3.5)

func _open_gamble() -> void:
	_gamble_open = true
	var ui := GAMBLE_UI.instantiate()
	get_tree().current_scene.add_child(ui)
	ui.tree_exited.connect(func(): _gamble_open = false)
	ui.open(price, _player)
