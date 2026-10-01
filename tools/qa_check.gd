extends Node
## QA 补丁验证 (并行窗口产出): 分数入分 / 散弹5发 / 复活浮台掩码 / Boss单路径击破+入分

var game: Node2D
var fails: Array[String] = []
var step := 0
var _wait := 0

func _ready() -> void:
	print("=== QA 补丁验证开始 ===")
	var gs: PackedScene = load("res://scenes/main.tscn")
	game = gs.instantiate()
	add_child(game)

func check(cond: bool, name: String) -> void:
	if cond:
		print("PASS: ", name)
	else:
		fails.append(name)
		print("FAIL: ", name)

func _due() -> bool:
	if _wait > 0:
		_wait -= 1
		return false
	return true

func _next(n: int, wait: int) -> void:
	step = n
	_wait = wait

func _physics_process(_d: float) -> void:
	match step:
		0:
			if _due():
				game.player.shield_t = 999.0        # 验证期间免死
				var sniper: Node = null
				for e in get_tree().get_nodes_in_group("enemies"):
					if e is EnemySniper:
						sniper = e
						break
				check(sniper != null, "找到狙击手")
				if sniper != null:
					Boot.score = 0
					sniper.kill()
					check(Boot.score == GameData.SCORE_SNIPER,
						"击杀敌人入分 (score=%d)" % Boot.score)
				_next(1, 2)
		1:
			if _due():
				var p = game.player
				p.pickup(GameData.W.S)
				check(p.weapon == GameData.W.S, "拾取散弹枪")
				p._try_shoot(game)
				var n: int = game.bullets_node.get_child_count()
				check(n == 5, "散弹一次5发 (实际%d)" % n)
				_next(2, 2)
		2:
			if _due():
				var p2 = game.player
				p2.respawn(Vector2(60, GameData.GROUND_Y))
				check((p2.collision_mask & GameData.L_PLATFORM) != 0,
					"复活后碰撞掩码含浮台层")
				_next(3, 2)
		3:
			if _due():
				Boot.score = 0
				game.boss_core.kill()
				_next(4, 160)
		4:
			if _due():
				check(game.level_done, "Boss击破→关卡完成(信号单路径)")
				check(Boot.score == GameData.SCORE_BOSS,
					"Boss击破入分 (score=%d)" % Boot.score)
				print("=== QA 验证结束: %d 失败 ===" % fails.size())
				for f in fails:
					print("  失败项: ", f)
				get_tree().quit(1 if fails.size() > 0 else 0)
