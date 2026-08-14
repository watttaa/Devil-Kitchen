extends Node
## 热更新加载器(PCK 补丁)。Autoload,须在其它 autoload/主场景前运行。
## 流程:
##   1. 启动先加载本地已下载的 patch.pck(离线也生效)。
##   2. 后台请求 version.json,若远端 patch_version 更高 -> 下载新 PCK -> 下次启动生效。
## 平台:安卓/桌面/Web 可用;iOS 禁止(App Store 规则)故自动跳过。

const MANIFEST_URL := "https://watttaa.github.io/Devil-Kitchen/version.json"
const LOCAL_PCK := "user://patch.pck"
const LOCAL_VER := "user://patch_version.txt"

var _http: HTTPRequest
var _remote_url := ""
var _remote_ver := 0

func _ready() -> void:
	# 编辑器内运行不加载补丁(否则旧 PCK 覆盖开发中的新代码)
	if OS.has_feature("editor"):
		return
	# iOS 不允许下载可执行代码,直接跳过
	if OS.get_name() == "iOS":
		return
	_load_local_pck()
	_check_remote()

## 加载本地已下载的补丁(同路径资源被覆盖)
func _load_local_pck() -> void:
	if FileAccess.file_exists(LOCAL_PCK):
		var ok := ProjectSettings.load_resource_pack(LOCAL_PCK, true)
		if ok:
			print("[PatchLoader] 已加载本地补丁 v%d" % _local_version())
		else:
			push_warning("[PatchLoader] 本地补丁加载失败,已忽略")

func _local_version() -> int:
	if not FileAccess.file_exists(LOCAL_VER):
		return 0
	var f := FileAccess.open(LOCAL_VER, FileAccess.READ)
	if f == null:
		return 0
	var v := int(f.get_as_text().strip_edges())
	f.close()
	return v

func _check_remote() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_manifest)
	var err := _http.request(MANIFEST_URL)
	if err != OK:
		push_warning("[PatchLoader] 无法请求版本清单(离线?),使用本地版本")

func _on_manifest(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if code != 200:
		return
	var data: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_DICTIONARY:
		return
	_remote_ver = int(data.get("patch_version", 0))
	_remote_url = str(data.get("pck_url", ""))
	if _remote_ver > _local_version() and _remote_url != "":
		_download_pck()

func _download_pck() -> void:
	var dl := HTTPRequest.new()
	add_child(dl)
	# 下到临时文件,校验成功后再替换正式补丁
	dl.download_file = LOCAL_PCK + ".tmp"
	dl.request_completed.connect(_on_pck_downloaded.bind(dl))
	var err := dl.request(_remote_url)
	if err != OK:
		push_warning("[PatchLoader] 补丁下载请求失败")

func _on_pck_downloaded(_result: int, code: int, _headers: PackedStringArray,
		_body: PackedByteArray, dl: HTTPRequest) -> void:
	dl.queue_free()
	if code != 200 and code != 302:
		push_warning("[PatchLoader] 补丁下载失败 HTTP %d" % code)
		return
	var tmp := LOCAL_PCK + ".tmp"
	if not FileAccess.file_exists(tmp):
		return
	# 覆盖正式补丁 + 写入版本号(下次启动 _load_local_pck 生效)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(LOCAL_PCK))
	DirAccess.rename_absolute(
		ProjectSettings.globalize_path(tmp),
		ProjectSettings.globalize_path(LOCAL_PCK))
	var f := FileAccess.open(LOCAL_VER, FileAccess.WRITE)
	if f:
		f.store_string(str(_remote_ver))
		f.close()
	print("[PatchLoader] 已下载补丁 v%d,重启游戏后生效" % _remote_ver)
	updated.emit(_remote_ver)

signal updated(version: int)
