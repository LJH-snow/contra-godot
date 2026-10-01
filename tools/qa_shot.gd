extends Node
## QA 截图: 无护盾, 拍新素材在游戏内的真实姿态 (tools/shots_qa/)

var game: Node2D
var step := 0
var _wait := 60

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tools/shots_qa"))
	var gs: PackedScene = load("res://scenes/main.tscn")
	game = gs.instantiate()
	add_child(game)

func _shot(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://tools/shots_qa/%s.png" % name))
	print("shot: ", name)

func _next(n: int, wait: int) -> void:
	step = n
	_wait = wait

func _physics_process(_d: float) -> void:
	_wait -= 1
	if _wait > 0:
		return
	var p = game.player
	match step:
		0:
			_shot("10_spawn_idle")
			_next(1, 30)
		1:
			p.position = Vector2(760, 120)     # 浮台区
			p.velocity = Vector2.ZERO
			_next(2, 40)
		2:
			_shot("11_platform_stand")
			p.pickup(GameData.W.S)             # 散弹枪射击姿态
			_next(3, 20)
		3:
			p._try_shoot(game)
			_next(4, 6)
		4:
			_shot("12_spread_fire")
			p.weapon = GameData.W.NORMAL
			p.velocity.y = -330.0              # 跳起翻滚
			_next(5, 12)
		5:
			_shot("13_jump_tumble")
			p.position = Vector2(760, 100)
			p.velocity = Vector2.ZERO
			_next(6, 30)
		6:
			Input.action_press("move_down")    # 卧倒
			_next(7, 20)
		7:
			_shot("14_prone")
			Input.action_release("move_down")
			p.position = Vector2(3340, GameData.GROUND_Y)   # Boss 堡垒前
			p.velocity = Vector2.ZERO
			_next(8, 50)                                    # 等 Boss 触发
		8:
			game.boss_wall.close_gate()                     # 关闸: 闸门遮核心
			_next(9, 8)
		9:
			_shot("15_boss_closed")
			game.boss_wall.open_gate()                      # 开闸: 露出发光核心
			p._try_shoot(game)
			_next(10, 8)
		10:
			_shot("16_boss_open")
			print("QA 截图完成")
			get_tree().quit(0)
