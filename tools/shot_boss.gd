extends Node
## Boss 视觉验收截图: 关门/开门/平射命中三个状态 (tools/shots_boss/)

var game: Node2D
var step := 0
var _wait := 90

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tools/shots_boss"))
	Boot.player_count = 1
	Boot.level = 1
	var gs: PackedScene = load("res://scenes/main.tscn")
	game = gs.instantiate()
	add_child(game)

func _shot(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://tools/shots_boss/%s.png" % name))
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
			p.shield_t = 999.0
			p._ring.scale = Vector2(0.01, 0.01)
			p.position = Vector2(3260.0, 200.0)
			_next(1, 200)                     # 越过 intro, 触发 Boss
		1:
			_shot("boss_closed")              # 关门态: 闸门遮住核心
			_next(2, 240)                     # 等下一次 toggle 开门
		2:
			if not game.boss_core.open:
				_next(2, 30)
				return
			_shot("boss_open")                # 开门态: 核心暴露在墙底左角
			var b := Bullet.new()
			b.setup(p.muzzle_pos(Vector2(1, 0)), Vector2(1, 0), GameData.W.NORMAL)
			game.bullets_node.add_child(b)
			_next(3, 6)
		3:
			_shot("boss_flatshot")            # 平射弹道瞬间
			print("=== Boss 截图完成 ===")
			get_tree().quit(0)
