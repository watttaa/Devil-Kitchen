extends Area2D
class_name Pickup
## 通用触碰拾取物(任务 4.3 / 8.x / 9.x):小费/弹药/回血/食谱/调料。
## 玩家身体进入即生效。collision_mask 检测玩家身体层(2)。

enum Kind { TIPS, AMMO, HEAL, RECIPE, SEASONING }

@export var kind: Kind = Kind.TIPS
@export var amount: int = 1
@export var recipe: RecipeData
@export var seasoning: SeasoningData

@onready var vis: Sprite2D = $Vis
@onready var label: Label = $Label

var _bob: float = 0.0
var _base_scale: Vector2 = Vector2.ONE

const MAGNET_RANGE := 150.0
const MAGNET_SPEED := 520.0

const TEX := {
	Kind.TIPS: "res://kenney_food-kit/Previews/cheese.png",
	Kind.AMMO: "res://kenney_food-kit/Previews/shaker-pepper.png",
	Kind.HEAL: "res://kenney_food-kit/Previews/lemon.png",
	Kind.RECIPE: "res://kenney_food-kit/Previews/salad.png",
	Kind.SEASONING: "res://kenney_food-kit/Previews/shaker-salt.png",
}

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_setup_visual()
	_bob = randf() * TAU
	_base_scale = vis.scale
	vis.scale = Vector2.ZERO
	var t := create_tween()
	t.tween_property(vis, "scale", _base_scale, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	_bob += delta * 3.0
	vis.position.y = sin(_bob) * 3.0
	vis.rotation = sin(_bob * 0.5) * 0.18
	var p := get_tree().get_first_node_in_group("player")
	if p:
		var to: Vector2 = (p as Node2D).global_position - global_position
		var d: float = to.length()
		if d < MAGNET_RANGE and d > 1.0:
			var pull: float = MAGNET_SPEED * (1.0 - d / MAGNET_RANGE)
			global_position += to / d * pull * delta

func _setup_visual() -> void:
	var tex: Texture2D = load(TEX[kind])
	if tex:
		vis.texture = tex
		var w: float = maxi(tex.get_width(), 1)
		vis.scale = Vector2.ONE * (32.0 / w)
	match kind:
		Kind.TIPS:
			label.text = "$" + str(amount)
		Kind.AMMO:
			label.text = "弹+" + str(amount)
		Kind.HEAL:
			label.text = "柠檬"
		Kind.RECIPE:
			label.text = recipe.display_name if recipe else "食谱"
		Kind.SEASONING:
			label.text = seasoning.display_name if seasoning else "调料"

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_apply(body)
	queue_free()

func _apply(player: Node) -> void:
	match kind:
		Kind.TIPS:
			RunContext.add_tips(amount)
		Kind.AMMO:
			player.add_ammo(amount)
		Kind.HEAL:
			player.health.heal(amount)
		Kind.RECIPE:
			if recipe:
				RunContext.add_recipe(recipe)
		Kind.SEASONING:
			if seasoning:
				RunContext.add_seasoning(seasoning)
