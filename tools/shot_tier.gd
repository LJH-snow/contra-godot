extends Node
## 官方对齐八件套视觉验收截图 (tools/shots_tier/)

var game: Node2D
var step := 0
var _wait := 30

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tools/shots_tier"))
	Boot.player_count = 1
	Boot.level = 1
	var gs: PackedScene = load("res://scenes/main.tscn")
	game = gs.instantiate()
	add_child(game)

func _shot(name: String) -> void:
	# 防御: 系统级按键/焦点事件可能打开暂停菜单, 截图前强制恢复
	if get_tree().paused:
		for n in get_tree().root.get_children():
			if n.name == "PauseMenu":
				n.call("_set_open", false)
		get_tree().paused = false
	DisplayServer.window_move_to_foreground()
	RenderingServer.force_draw()
	print("  [state] paused=%s level_done=%s p_dead=%s p_swim=%s p_sub=%s p_pos=%s enemies=%d items=%d" % [
		get_tree().paused, game.level_done,
		game.players[0].dead, game.players[0].swim, game.players[0].submerged,
		game.players[0].position, get_tree().get_nodes_in_group("enemies").size(),
		game.items_node.get_child_count()])
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://tools/shots_tier/%s.png" % name))
	print("shot: ", name)

func _next(n: int, wait: int) -> void:
	step = n
	_wait = wait

func _place_player(x: float, y: float) -> void:
	var p: Player = game.players[0]
	p.position = Vector2(x, y)
	p.velocity = Vector2.ZERO
	p.invuln_t = 99.0
	game.cam_x = maxf(0.0, x - 120.0)
	game.position = Vector2(-game.cam_x, 0.0)

func _physics_process(_d: float) -> void:
	_wait -= 1
	if _wait > 0:
		return
	var p: Player = game.players[0]
	match step:
		0:
			p.shield_t = 999.0
			p._ring.scale = Vector2(0.01, 0.01)
			# 敌兵谱系: 红兵/跳兵/手雷兵 + 开花弹兵 同框
			_place_player(420.0, 200.0)
			var red := EnemyRunner.new()
			red.drops_weapon = true
			red.position = Vector2(300.0, 200.0)
			game.enemies_node.add_child(red)
			var jp := EnemyJumper.new()
			jp.position = Vector2(360.0, 200.0)
			game.enemies_node.add_child(jp)
			var gr := EnemyGrenadier.new()
			gr.position = Vector2(480.0, 200.0)
			game.enemies_node.add_child(gr)
			var bl := EnemyBlossom.new()
			bl.position = Vector2(540.0, 200.0)
			game.enemies_node.add_child(bl)
			_next(1, 50)
		1:
			_shot("t1_enemy_lineup")
			# 潜水: 玩家在河面
			_place_player(620.0, 120.0)
			_next(2, 70)
		2:
			_shot("t2_swim_surface")
			Input.action_press("p1_down")
			_next(3, 20)
		3:
			Input.action_release("p1_down")
			_shot("t3_submerged")
			# 震天鹰编队 (先回位玩家/相机, 再相对相机生成)
			for e in get_tree().get_nodes_in_group("enemies"):
				e.queue_free()
			_place_player(400.0, 200.0)
			for k in range(3):
				var eg := EnemyEagle.new()
				eg.setup_formation(Vector2(game.cam_x + 60.0 + k * 36.0, 70.0), k == 1, 70.0)
				game.enemies_node.add_child(eg)
			_next(4, 30)
		4:
			_shot("t4_eagle_convoy")
			print("=== 八件套截图完成 ===")
			get_tree().quit(0)
