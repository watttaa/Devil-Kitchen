extends Resource
class_name SeasoningData
## 调料(主动消耗道具,任务 9.x):使用后获得即时效果并消耗一份。

enum Effect { HEAL, DAMAGE_BUFF, SLOW_ENEMIES }

@export var id: String = "seasoning"
@export var display_name: String = "调料"
@export_multiline var description: String = ""
@export var effect: Effect = Effect.HEAL
@export var magnitude: float = 1.0      # HEAL:半心数;DAMAGE_BUFF:倍率;SLOW:减速比例
@export var duration: float = 5.0       # 持续型效果时长(秒)
