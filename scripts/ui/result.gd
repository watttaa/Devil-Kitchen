extends Control
## 结算界面(任务 11.x):显示胜负、楼层、小费,提供重开/返回主菜单。

func _ready() -> void:
	GameManager.state = GameManager.State.RESULT
	var newly := ContentDB.check_unlocks()
	if GameManager.last_win:
		$Panel/Title.text = "下班成功!"
		$Panel/Flavor.text = "你没再抡刀——甩一颗蛋、倒进隔夜饭,猛火颠三下。
一盘热腾腾的蛋炒饭端到师父面前,他一口下肚,眼泪唰地就下来了:
「……还是你炒得香。加了猪油对吧。」
「啪!」那纸卖身契自己烧成了灰,广播里的声音尖叫着断了电,魔鬼餐厅当场倒闭。
师徒俩在街角支了个小摊,招牌就俩字:现结。
(据说那位魔鬼老板,又跑去别的城开分店了……)"
	else:
		$Panel/Title.text = "你被端上桌了…"
		var f := GameManager.last_floor
		var flavor := ""
		match f:
			1: flavor = "第一层都没熬过去。
后厨把你腌上了,贴张标签:「本周特价 · 见习小炒 · 买一送一」。"
			2: flavor = "烤箱「叮」的一声——出炉了。
你成了今日限定焦糖布丁,收获五星好评:「火候刚好,就是有点吵。」"
			_: flavor = "就差最后那一扇门。
广播里那个声音慢悠悠地笑:「新来的,签个字吧。」
地狱大厨别过脸去,把你排进了下周班表:「明天早八,别迟到。」"
		$Panel/Flavor.text = flavor
	var info := "到达第 %d 层   收集窝囊费 $%d   累计击杀 %d" % [
		GameManager.last_floor, GameManager.last_tips, SaveSystem.stat("kills")]
	if not newly.is_empty():
		info += "\n新解锁: " + ", ".join(newly)
	$Panel/Info.text = info
	$Panel/Retry.pressed.connect(GameManager.start_game)
	$Panel/Menu.pressed.connect(GameManager.to_main_menu)
	$Panel/Retry.grab_focus()
