extends Resource
class_name RecipeData
## 食谱(被动遗物,任务 9.x):本局永久生效,可叠加。synergy_tags 用于组合检测。

@export var id: String = "recipe"
@export var display_name: String = "食谱"
@export_multiline var description: String = ""
@export var damage_mult: float = 1.0
@export var attack_speed_mult: float = 1.0
@export var move_speed_mult: float = 1.0
@export var heal_on_room_clear: int = 0       # 每清一房回复的半心数
@export var synergy_tags: Array[String] = []
