extends Resource
class_name EventData
## 随机事件(扩张 3.1):描述 + 选项数组,每选项含效果指令枚举与数值。
## 由事件房/祭坛房进入时随机抽取并弹出暂停式选择 UI。

enum Effect {
	NONE,
	HEAL,              # +生命
	DAMAGE,            # -生命
	ADD_TIPS,          # +小费
	LOSE_TIPS,         # -小费(不低于 0)
	GIVE_RANDOM_RECIPE,# 直接获得一个随机食谱
	ADD_TEMP_BUFF,     # 临时伤害增益(数值=倍率,duration 由 SeasoningData 路径不取,这里用固定时长)
	SPAWN_ENEMIES,     # 立即刷出敌人(数值=数量,难度高但奖励另算)
}

@export var id: String = "event"
@export var title: String = "事件"
@export_multiline var description: String = ""
@export var options: Array[Dictionary] = []
# options 元素示例:
# { "label": "喝下药水", "effect": Effect.HEAL, "amount": 2 }
# { "label": "献上小费", "effect": Effect.LOSE_TIPS, "amount": 10, "reward_recipe": true }
