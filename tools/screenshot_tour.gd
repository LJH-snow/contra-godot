extends Node
## 截图巡游: 窗口模式运行游戏, 在关键位置截图到 tools/shots/

const DIR := "res://tools/shots"

var game: Node2D
var step := 0
var _wait := 40

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	var ts: PackedScene = load("res://scenes/title.tscn")
	add_child(ts.instantiate())

func _physics_process(_d: float) -> void:
	_wait -= 1
	if _wait > 0:
		return
	match step:
		0:
			_shot("01_title")
			_next(1, 10)
		1:
			# 清掉标题, 进主场景
			for c in get_children():
				c.queue_free()
			var gs: PackedScene = load("res://scenes/main.tscn")
			game = gs.instantiate()
			add_child(game)
			_next(2, 50)
		2:
			game.player.shield_t = 999.0     # 巡游期间免死
			_shot("02_start")
			_next(3, 70)
		3:
			# 跳到浮台区
			_tp(760, 100)
			_next(4, 60)
		4:
			_shot("03_platforms")
			_next(5, 40)
		5:
			_tp(1440, 150)
			_next(6, 70)
		6:
			_shot("04_bridge")
			_next(7, 40)
		7:
			_tp(3300, 170)
			_next(8, 70)
		8:
			_shot("05_boss")
			if game.boss_core != null and is_instance_valid(game.boss_core):
				game.boss_core.set_open(true)
			_next(9, 30)
		9:
			if game.boss_wall != null:
				game.boss_wall.close_gate()
			_shot("06_boss_closed")
			_next(10, 10)
		10:
			print("截图完成")
			get_tree().quit(0)

func _tp(x: float, y: float) -> void:
	game.player.position = Vector2(x, y)
	game.player.velocity = Vector2.ZERO

func _next(n: int, wait: int) -> void:
	step = n
	_wait = wait

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(DIR + "/" + name + ".png"))
	print("已截图: ", name)
