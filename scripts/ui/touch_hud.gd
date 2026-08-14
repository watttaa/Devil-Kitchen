extends Control
## 移动端触屏 HUD:左右虚拟摇杆 + 冲刺/近战/调料按钮。
## 仅在触屏设备显示;桌面端隐藏,不干扰键鼠。

@onready var dash_btn: Button = $Dash
@onready var melee_btn: Button = $Melee
@onready var seasoning_btn: Button = $Seasoning
@onready var interact_btn: Button = $Interact

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not TouchInput.enabled:
		visible = false
		set_process(false)
		return
	dash_btn.pressed.connect(TouchInput.press_dash)
	melee_btn.pressed.connect(TouchInput.tap_melee)
	seasoning_btn.pressed.connect(TouchInput.press_seasoning)
	interact_btn.pressed.connect(TouchInput.press_interact)

func _process(_delta: float) -> void:
	# 暂停时隐藏,避免摇杆盖住暂停菜单
	visible = not get_tree().paused
