extends Node
## 结局画面截图: 窗口模式加载 ending.tscn, 2.5s 后截图退出

const DIR := "res://tools/shots"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	var es: PackedScene = load("res://scenes/ending.tscn")
	add_child(es.instantiate())
	await get_tree().create_timer(2.5).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(DIR + "/07_ending.png"))
	print("已截图: 07_ending")
	get_tree().quit(0)
