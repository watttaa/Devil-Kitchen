extends Resource
class_name NarrativeData
## 叙事节点(扩张 5.x):触发点 id + 文本页,由对应控制器查表呈现,可跳过。

@export var id: String = "narrative"
@export var trigger: String = ""   # 如 floor1_enter / boss2_before / boss3_after
@export var title: String = ""
@export_multiline var lines: PackedStringArray = PackedStringArray()
## 每页说话人 id(与 lines 平行,可短于 lines,缺省按 narrator 旁白)
## 可选值:narrator / ache / chef / dessert / tomato / plate
@export var speakers: PackedStringArray = PackedStringArray()
