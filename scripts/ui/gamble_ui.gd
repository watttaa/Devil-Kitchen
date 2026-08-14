extends CanvasLayer
## 幸运老虎机(赌博台小游戏):花小费转 3 轴,连线中奖。暂停式,可反复抽,按返回离开。

const SYMBOLS := [
	{"id": "tomato", "tex": "res://kenney_food-kit/Previews/tomato.png", "w": 5},
	{"id": "cheese", "tex": "res://kenney_food-kit/Previews/cheese.png", "w": 5},
	{"id": "egg", "tex": "res://kenney_food-kit/Previews/egg-cooked.png", "w": 4},
	{"id": "paprika", "tex": "res://kenney_food-kit/Previews/paprika.png", "w": 3},
	{"id": "cake", "tex": "res://kenney_food-kit/Previews/cake.png", "w": 2},
	{"id": "star", "tex": "res://kenney_food-kit/Previews/cake-birthday.png", "w": 1},
]

var price: int = 10
var _player: Node = null
var _spinning: bool = false
var _tex_by_id: Dictionary = {}

@onready var reels: Array = [
	$Root/Panel/Reels/R0, $Root/Panel/Reels/R1, $Root/Panel/Reels/R2]
@onready var result_label: Label = $Root/Panel/Result
@onready var balance_label: Label = $Root/Panel/Balance
@onready var spin_btn: Button = $Root/Panel/Buttons/Spin
@onready var back_btn: Button = $Root/Panel/Buttons/Back

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for s in SYMBOLS:
		_tex_by_id[s["id"]] = load(s["tex"])
	for r in reels:
		_set_reel(r, "star")
	spin_btn.pressed.connect(_spin)
	back_btn.pressed.connect(_close)

func open(spin_price: int, player: Node) -> void:
	price = spin_price
	_player = player
	spin_btn.text = "转一次 ($%d)" % price
	result_label.text = "拉下拉杆,试试手气!"
	_update_balance()
	visible = true
	GameManager.push_pause(self)

func _update_balance() -> void:
	balance_label.text = "窝囊费余额:$%d" % RunContext.tips

func _set_reel(rect: TextureRect, id: String) -> void:
	rect.texture = _tex_by_id.get(id, null)

func _rand_id() -> String:
	return SYMBOLS[RunContext.rng.randi() % SYMBOLS.size()]["id"]

func _pick_weighted() -> String:
	var total := 0
	for s in SYMBOLS:
		total += int(s["w"])
	var roll := RunContext.rng.randi() % total
	for s in SYMBOLS:
		roll -= int(s["w"])
		if roll < 0:
			return s["id"]
	return SYMBOLS[0]["id"]

func _spin() -> void:
	if _spinning:
		return
	if not RunContext.spend_tips(price):
		result_label.text = "窝囊费不够啦,先去多赚点!"
		return
	_spinning = true
	spin_btn.disabled = true
	_update_balance()
	result_label.text = "转啊转……"
	var final_ids := [_pick_weighted(), _pick_weighted(), _pick_weighted()]
	for t in 12:
		for r in reels:
			_set_reel(r, _rand_id())
		await get_tree().create_timer(0.05).timeout
	for i in 3:
		_set_reel(reels[i], final_ids[i])
		await get_tree().create_timer(0.18).timeout
	_evaluate(final_ids)
	_spinning = false
	spin_btn.disabled = false

func _evaluate(ids: Array) -> void:
	var a: String = ids[0]
	var b: String = ids[1]
	var c: String = ids[2]
	if a == b and b == c:
		if a == "star":
			if _player:
				_player.health.heal(99)
			RunContext.add_recipe(ContentDB.random_recipe())
			RunContext.add_recipe(ContentDB.random_recipe())
			RunContext.add_tips(30)
			result_label.text = "★★★ 头奖!回满血 + 2 食谱 + $30!"
		else:
			_player.health.heal(2)
			RunContext.add_recipe(ContentDB.random_recipe())
			result_label.text = "三连中奖!食谱 + 回血 2"
	elif a == b or b == c or a == c:
		if RunContext.rng.randf() < 0.5:
			_player.health.heal(1)
			result_label.text = "两连!回血 1"
		else:
			RunContext.add_tips(8)
			result_label.text = "两连!返还 $8"
	else:
		result_label.text = "差一点……下次一定!"
	_update_balance()

func _close() -> void:
	visible = false
	GameManager.pop_pause(self)
	queue_free()
