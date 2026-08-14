extends CanvasLayer
## 事件选择 UI(扩张 3.2):暂停游戏,展示描述与选项,选定后执行效果并恢复。
## process_mode=ALWAYS 以便暂停时仍可交互。

signal option_chosen(effect: int, amount: int, extra: Dictionary)

# EventData.Effect 枚举值(跨类枚举访问不稳,用整数常量)
const EFF_NONE := 0
const EFF_HEAL := 1
const EFF_DAMAGE := 2
const EFF_ADD_TIPS := 3
const EFF_LOSE_TIPS := 4
const EFF_GIVE_RECIPE := 5
const EFF_TEMP_BUFF := 6
const EFF_SPAWN := 7

@onready var title_label: Label = $Root/Panel/Title
@onready var desc_label: Label = $Root/Panel/Description
@onready var options_box: VBoxContainer = $Root/Panel/Options

const OPTION_BTN := preload("res://scripts/ui/event_option_button.gd")
var _event: EventData = null

func _ready() -> void:
	visible = false

func present(event: EventData) -> void:
	_event = event
	title_label.text = event.title
	desc_label.text = event.description
	for c in options_box.get_children():
		c.queue_free()
	for opt in event.options:
		var btn := Button.new()
		btn.set_script(OPTION_BTN)
		btn.text = str(opt.get("label", "?"))
		btn.pressed.connect(_on_option_pressed.bind(opt))
		options_box.add_child(btn)
	visible = true
	GameManager.push_pause(self)

func _on_option_pressed(opt: Dictionary) -> void:
	visible = false
	GameManager.pop_pause(self)
	var eff: int = int(opt.get("effect", EFF_NONE))
	var amt: int = int(opt.get("amount", 0))
	option_chosen.emit(eff, amt, opt)

## 由房间调用:执行效果指令
func execute(effect: int, amount: int, extra: Dictionary) -> void:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if effect == EFF_HEAL:
		if p: p.health.heal(amount)
	elif effect == EFF_DAMAGE:
		if p: p.health.take_damage(amount)
	elif effect == EFF_ADD_TIPS:
		RunContext.add_tips(amount)
	elif effect == EFF_LOSE_TIPS:
		var t := RunContext.tips
		RunContext.tips = maxi(t - amount, 0)
		RunContext.tips_changed.emit(RunContext.tips)
	elif effect == EFF_GIVE_RECIPE:
		RunContext.add_recipe(ContentDB.random_recipe())
	elif effect == EFF_TEMP_BUFF:
		if p: p.apply_temp_damage_buff(float(amount) / 100.0, 20.0)
	elif effect == EFF_SPAWN:
		pass
