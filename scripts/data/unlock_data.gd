extends Resource
class_name UnlockData
## 解锁条件(扩张 6.x):满足条件时把目标内容 id 记入持久存档。
## 条件类型用枚举,阈值与目标 id 由各字段决定。

enum Cond {
	STAT_KILLS,        # 累计击杀 >= threshold
	STAT_WINS,         # 累计通关 >= threshold
	STAT_BEST_FLOOR,   # 最高楼层 >= threshold
	KILLS_ENEMY,       # 击杀某怪种 >= threshold(用 enemy_id 指定)
}

@export var id: String = "unlock"
@export var target_content: String = ""   # 解锁后进池的内容 id(武器/食谱/调料/怪)
@export var condition: Cond = Cond.STAT_KILLS
@export var threshold: int = 0
@export var enemy_id: String = ""          # KILLS_ENEMY 条件:目标怪种 id
@export var display_name: String = ""
@export_multiline var hint: String = ""   # 未解锁时的条件提示
