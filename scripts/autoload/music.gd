extends Node
## 背景音乐(全程一首循环)。Autoload 单例 "Music"。
## 走 Master bus,受设置界面音量控制;暂停时继续播放。
## 把音频文件放到 BGM_PATH(建议 .ogg 且在导入面板勾 Loop)。

const BGM_PATH := "res://resources/卢广仲 - 刻在我心底的名字.mp3"

var _player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)
	if ResourceLoader.exists(BGM_PATH):
		var stream: AudioStream = load(BGM_PATH)
		# 未在导入面板勾 Loop 时,代码兜底开启循环
		if stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		elif stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = true
		elif stream is AudioStreamWAV:
			(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
		_player.stream = stream
		_player.play()
	else:
		push_warning("未找到 BGM:%s(把 .ogg 放到该路径即可)" % BGM_PATH)

func play() -> void:
	if _player.stream and not _player.playing:
		_player.play()

func stop() -> void:
	_player.stop()
