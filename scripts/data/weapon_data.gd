extends Resource
class_name WeaponData
## 武器配置(任务 3.2):近战/远程统一数据,存为 .tres,逻辑读取此配置。

enum Type { MELEE, RANGED }

@export var id: String = "weapon"
@export var display_name: String = "武器"
@export var type: Type = Type.MELEE
@export var damage: float = 20.0
@export var attack_interval: float = 0.4
@export var color: Color = Color(0.8, 0.8, 0.8)
@export var texture: Texture2D    # 武器精灵图
@export var texture_angle_offset: float = 0.0   # 贴图朝向校正(度):贴图默认指向与 +x 的夹角
@export var texture_flipped: bool = false       # 贴图握把/攻击端左右反了则勾选

# 近战专用
@export var melee_range: float = 42.0
@export var melee_radius: float = 30.0
@export var melee_active_time: float = 0.12

# 远程专用
@export var magazine_size: int = 12
@export var projectile_speed: float = 750.0
@export var projectiles_per_shot: int = 1
@export var spread_degrees: float = 0.0
@export var projectile_color: Color = Color(1, 0.5, 0.1)
@export var projectile_scale: float = 1.0    # 弹丸尺寸倍率(机关枪小粒子=0.5,大弹=1.5)
@export var fire_jitter_degrees: float = 0.0 # 每发额外随机偏角(机关枪扫射手感)
@export var stream: bool = false             # true=持续喷射流(番茄汁射线):每帧连续吐弹
