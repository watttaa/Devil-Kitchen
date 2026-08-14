extends Resource
class_name EnemyData
## 食材怪配置(任务 5.1)。behavior 决定 AI 行为。

enum Behavior { CHASER, TURRET, SHOOTER }

@export var id: String = "enemy"
@export var display_name: String = "食材怪"
@export var behavior: Behavior = Behavior.CHASER
@export var max_health: float = 40.0
@export var move_speed: float = 120.0
@export var sense_range: float = 420.0
@export var attack_range: float = 220.0
@export var attack_interval: float = 1.2
@export var contact_damage: float = 1.0     # 对玩家(半心)
@export var color: Color = Color(0.9, 0.4, 0.3)
@export var body_radius: float = 22.0
@export var texture: Texture2D    # 精灵图(食材 PNG)

# 远程行为投射物
@export var projectile_speed: float = 460.0
@export var projectile_damage: float = 1.0

# 掉落
@export var tips_drop: int = 3
@export var ammo_drop_chance: float = 0.3
@export var ammo_amount: int = 6
