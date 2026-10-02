extends Node
## 无头自动化测试: 驱动玩法系统并断言 (全部通过则 exit 0)
## 步骤模式: 进入步骤后先等 _wait 帧, 再执行一次检查并进入下一步

var game: Node2D
var fails: Array[String] = []
var step := 0
var _wait := 0
var _tag_runner: EnemyRunner
var _tag_runner2: EnemyRunner
var _step9_ticks := 0
var _total_ticks := 0
var _jump_min_y := 99999.0

func _ready() -> void:
	print("=== 魂斗罗自动化测试开始 ===")
	Boot.player_count = 2
	var gs: PackedScene = load("res://scenes/main.tscn")
	game = gs.instantiate()
	add_child(game)

func check(cond: bool, name: String) -> void:
	if cond:
		print("PASS: ", name)
	else:
		fails.append(name)
		print("FAIL: ", name)

## 当前步骤等待结束返回 true (调用方随后执行并推进步骤)
func _due() -> bool:
	if _wait > 0:
		_wait -= 1
		return false
	return true

func _next(n: int, wait: int) -> void:
	step = n
	_wait = wait

func _physics_process(_d: float) -> void:
	_total_ticks += 1
	if _total_ticks > 20000:
		print("超时强制退出")
		get_tree().quit(1)
		return
	match step:
		0:
			if _due():
				check(game.player != null, "玩家已生成")
				check(game.players.size() == 2, "双人模式: P2已生成(共%d人)" % game.players.size())
				check(game.world_node.get_child_count() > 100, "地形已构建(%d块)" % game.world_node.get_child_count())
				check(get_tree().get_nodes_in_group("enemies").size() >= 8, "静态敌人已布置")
				# 最高分存档: 破纪录生效, 低分无效, 测后恢复
				var prev_high: int = Boot.high_score
				var broke: bool = Boot.submit_score(prev_high + 12345)
				check(broke and Boot.high_score == prev_high + 12345, "最高分破纪录写入")
				check(not Boot.submit_score(prev_high) and Boot.high_score == prev_high + 12345, "低分不覆盖最高分")
				Boot.submit_score(prev_high)
				_next(1, 10)
		1:
			# 持续射击, 中途放靶子跑兵
			if game.player != null and not game.player.dead:
				game.player._try_shoot(game)
			if _wait == 30 and _tag_runner == null:
				_tag_runner = EnemyRunner.new()
				_tag_runner.position = game.player.position + Vector2(130, -30)
				game.enemies_node.add_child(_tag_runner)
			if _due():
				check(game.bullets_node.get_child_count() > 0, "子弹已生成")
				check(not is_instance_valid(_tag_runner), "子弹击杀靶子跑兵")
				_next(2, 2)
		2:
			if _due():
				game.player.pickup(GameData.W.S)
				check(game.player.weapon == GameData.W.S, "拾取散弹枪")
				game.player.pickup(GameData.W.B)
				_next(3, 2)
		3:
			if _due():
				check(game.player.shield_t > 0.0, "B护盾生效")
				_tag_runner2 = EnemyRunner.new()
				_tag_runner2.position = game.player.position + Vector2(2, -10)
				game.enemies_node.add_child(_tag_runner2)
				_next(4, 40)
		4:
			if _due():
				check(not is_instance_valid(_tag_runner2), "护盾秒杀触碰敌人(出生重叠)")
				game.player.shield_t = 0.0
				game.player.invuln_t = 0.0
				game.player.hurt(null)
				_next(5, 5)
		5:
			if _due():
				check(game.player.dead, "玩家受击死亡")
				check(game.player.lives == Boot.start_lives - 1, "生命-1(余%d)" % game.player.lives)
				_next(6, 110)
		6:
			if _due():
				check(not game.player.dead, "自动复活完成")
				check(game.player.invuln_t > 0.0, "复活保护生效(%.2fs)" % game.player.invuln_t)
				_next(7, 10)
		7:
			# 跳跃高度: 传送空地, 按住跳跃键 70 tick, 顶点必须够到第二层浮台高度(116)
			if _wait == 8:
				game.player.position = Vector2(100, GameData.GROUND_Y)
				game.player.velocity = Vector2.ZERO
			if _due():
				Input.action_press("p1_jump")
				_jump_min_y = 99999.0
				_next(8, 70)
		8:
			_jump_min_y = minf(_jump_min_y, game.player.position.y)
			if _due():
				Input.action_release("p1_jump")
				check(_jump_min_y < 122.0, "跳跃高度够到第二层浮台(顶点y=%.0f, 需<122)" % _jump_min_y)
				if game.bridge != null and game.bridge.segs.size() > 0:
					game.player.position = Vector2(game.bridge.position.x + 8, game.bridge.position.y - 6)
					game.player.velocity = Vector2.ZERO
				_next(9, 100)
		9:
			if _due():
				if game.bridge != null:
					check(game.bridge._lit >= 0, "吊桥逐段爆炸(已炸%d段)" % (game.bridge._lit + 1))
				# 走到墙前(模拟真实推进, 相机到位后核心才在射程内)
				game.player.position = Vector2(3300, GameData.GROUND_Y - 30)
				game.player.velocity = Vector2.ZERO
				if game.player.dead:
					game.player.respawn(game.player.position)
				_next(10, 30)
		10:
			if _due():
				check(game.boss_active, "Boss战已触发")
				check(game._gate_open, "Boss闸门开启")
				_next(11, 2)
		11:
			# 持续对核心输出直至击破
			_step9_ticks += 1
			if game.level_done:
				check(true, "Boss被击破,关卡完成")
				_next(12, 0)
			elif _step9_ticks > 1200:
				check(false, "Boss未能被击破")
				_next(12, 0)
			elif game.boss_core != null and is_instance_valid(game.boss_core):
				game.boss_core.set_open(true)
				var b := Bullet.new()
				b.setup(game.boss_core.position + Vector2(-30, -14), Vector2.RIGHT, GameData.W.NORMAL)
				game.bullets_node.add_child(b)
		12:
			print("=== 测试结束: %d 失败 ===" % fails.size())
			for f in fails:
				print("  失败项: ", f)
			get_tree().quit(1 if fails.size() > 0 else 0)
