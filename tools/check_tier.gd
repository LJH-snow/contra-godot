extends Node
## 官方对齐八件套验收: 下落穿透/潜水/红兵掉枪/跳兵/手雷兵/开花弹兵/震天鹰/滚石

var game: Node2D
var fails: Array[String] = []
var step := 0
var _wait := 0
var _min_y := 99999.0
var _saw_grenade := false
var _lives0 := 0
var _items0 := 0
var _rock: EnemyRock
var _blossom: EnemyBlossom
var _eagles: Array = []

func _ready() -> void:
	print("=== 官方对齐八件套验收开始 ===")
	Boot.player_count = 1
	Boot.level = 1
	var gs: PackedScene = load("res://scenes/main.tscn")
	game = gs.instantiate()
	add_child(game)
	_next(0, 10)

func check(ok: bool, msg: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + msg)
	if not ok:
		fails.append(msg)

func _clear_field() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	for n in game.enemies_node.get_children():
		if n is EBullet:
			n.queue_free()
	game._spawn_t = 99999.0
	game._capsule_t = 99999.0
	game._rock_t = 99999.0

## 玩家定位 + 相机回置 (相机只进不退, 测试需同步回拉)
func _place_player(x: float, y: float) -> void:
	var p: Player = game.players[0]
	p.position = Vector2(x, y)
	p.velocity = Vector2.ZERO
	game.cam_x = maxf(0.0, x - 120.0)
	game.cam_y = 0.0
	game.position = Vector2(-game.cam_x, 0.0)

func _due() -> bool:
	_wait -= 1
	return _wait <= 0

func _next(n: int, wait: int) -> void:
	step = n
	_wait = wait

func _release_all() -> void:
	for a in ["p1_down", "p1_jump", "p1_left", "p1_right", "p1_up", "p1_shoot"]:
		Input.action_release(a)

func _physics_process(_d: float) -> void:
	var p: Player = game.players[0] if not game.players.is_empty() else null
	if p == null:
		return
	match step:
		0:
			_clear_field()
			p.invuln_t = 99.0
			# 【1】下落穿透: 站上浮台 (368..432@144) 后 ↓+跳
			_place_player(400.0, 144.0)
			_next(1, 20)
		1:
			if not _due():
				return
			if not p.on_ground:
				_next(1, 10)
				return
			check(game.on_platform_at(400.0, 144.0), "浮台判定 on_platform_at")
			Input.action_press("p1_down")
			Input.action_press("p1_jump")
			_next(2, 6)
		2:
			if _due():
				_release_all()
				_next(3, 45)
		3:
			if _due():
				check(p.position.y > 158.0, "↓+跳 已穿透浮台落到下层 (y=%.0f)" % p.position.y)
				# 【2】潜水: 空投到丛林河流缺口 [592,656] 上空
				_place_player(620.0, 120.0)
				_next(4, 90)
		4:
			if _due():
				if not p.swim:
					check(false, "落水后进入游泳状态")
					_next(99, 1)
					return
				check(absf(p.position.y - 210.0) < 6.0, "落水浮于水面 (y=%.0f)" % p.position.y)
				check(p.lives == Boot.start_lives, "落水不即死(游泳替代)")
				Input.action_press("p1_down")
				_next(5, 10)
		5:
			if _due():
				check(p.submerged, "按下即下潜")
				var eb := EBullet.new()
				eb.setup(p.position + Vector2(0, -14), Vector2.RIGHT, 10.0)
				game.enemies_node.add_child(eb)
				_next(6, 30)
		6:
			if _due():
				Input.action_release("p1_down")
				check(p.lives == Boot.start_lives, "下潜期间敌弹掠过头顶无伤")
				Input.action_press("p1_jump")
				Input.action_press("p1_right")   # 向右岸跃出, 免落回水里
				_next(7, 4)
		7:
			if _due():
				Input.action_release("p1_jump")
				Input.action_release("p1_right")
				check(not p.swim and not p.submerged and p.position.y < 200.0,
					"按跳跃键跃出水面 (y=%.0f)" % p.position.y)
				_next(8, 1)
		8:
			if _due():
				pass
				# 【3】红兵掉枪
				_clear_field()
				_place_player(400.0, 200.0)
				_items0 = game.items_node.get_child_count()
				var red := EnemyRunner.new()
				red.drops_weapon = true
				red.position = Vector2(300.0, 200.0)
				game.enemies_node.add_child(red)
				_next(9, 10)
		9:
			if _due():
				var red: EnemyRunner = null
				for e in get_tree().get_nodes_in_group("enemies"):
					if e is EnemyRunner and e.drops_weapon:
						red = e
				if red == null:
					check(false, "红兵在场")
					_next(99, 1)
					return
				red.kill()
				_next(10, 10)
		10:
			if _due():
				check(game.items_node.get_child_count() > _items0, "红兵击杀掉落武器箱")
				# 【4】跳兵
				_clear_field()
				_place_player(400.0, 200.0)
				var jp := EnemyJumper.new()
				jp.position = Vector2(300.0, 200.0)
				game.enemies_node.add_child(jp)
				jp.run_speed = 0.0                  # 定住(须在入树后, _ready会随机化速度)
				_min_y = 99999.0
				_next(11, 130)
		11:
			var jp: EnemyJumper = null
			for e in get_tree().get_nodes_in_group("enemies"):
				if e is EnemyJumper:
					jp = e
			if jp == null:
				if _due():
					check(false, "跳兵在场")
					_next(99, 1)
				return
			_min_y = minf(_min_y, jp.position.y)
			if _due():
				check(_min_y < 165.0, "跳兵周期起跳 (最高点 y=%.0f)" % _min_y)
				# 【5】手雷兵
				_clear_field()
				p.invuln_t = 99.0
				_place_player(430.0, 200.0)
				var gr := EnemyGrenadier.new()
				gr.position = Vector2(300.0, 200.0)
				game.enemies_node.add_child(gr)
				gr.run_speed = 0.0                  # 定住(须在入树后): 只验证抛雷
				_saw_grenade = false
				_next(12, 220)
		12:
			for n in game.enemies_node.get_children():
				if n is EBullet and n.grav > 0.0:
					_saw_grenade = true
			if _due():
				check(_saw_grenade, "手雷兵抛出抛物线手雷")
				# 【6】开花弹兵
				_clear_field()
				_blossom = EnemyBlossom.new()
				_blossom.position = Vector2(700.0, 200.0)
				game.enemies_node.add_child(_blossom)
				_next(13, 10)
		13:
			if _due():
				_blossom.damage(5, Vector2.RIGHT)
				_next(14, 5)
		14:
			if _due():
				if not is_instance_valid(_blossom):
					check(false, "开花弹兵不可击毙")
					_next(99, 1)
					return
				check(_blossom.hp > 1000, "开花弹兵受击无伤 (hp=%d)" % _blossom.hp)
				game.eagle_wipe()
				_next(15, 5)
		15:
			if _due():
				check(is_instance_valid(_blossom), "金鹰清屏不误杀开花弹兵")
				# 【7】震天鹰: 三鹰编队, 击落中间
				_clear_field()
				_place_player(400.0, 200.0)
				var hostage := EnemyRunner.new()
				hostage.position = Vector2(300.0, 200.0)
				game.enemies_node.add_child(hostage)
				_eagles = []
				for k in range(3):
					var eg := EnemyEagle.new()
					eg.setup_formation(Vector2(200.0 + k * 36.0, 70.0), k == 1, 70.0)
					game.enemies_node.add_child(eg)
					_eagles.append(eg)
				_lives0 = p.lives
				_next(16, 10)
		16:
			if _due():
				var mid: EnemyEagle = _eagles[1]
				mid.kill()
				_next(17, 10)
		17:
			if _due():
				check(p.lives == _lives0 + 1, "击落中间金鹰 +1 命 (%d→%d)" % [_lives0, p.lives])
				var hostage_alive := false
				for e in get_tree().get_nodes_in_group("enemies"):
					if e is EnemyRunner:
						hostage_alive = true
				check(not hostage_alive, "金鹰闪击清屏 (人质跑兵被清除)")
				# 【8】滚石: 自然落地摔碎 (无礼)
				_clear_field()
				_rock = EnemyRock.new()
				_rock.position = Vector2(400.0, 90.0)
				game.enemies_node.add_child(_rock)
				_lives0 = p.lives
				_next(18, 80)
		18:
			if _due():
				check(not is_instance_valid(_rock), "滚石落到浮台摔碎消失")
				check(p.lives == _lives0, "自然摔碎不给 1UP")
				_rock = EnemyRock.new()
				_rock.position = Vector2(400.0, 120.0)
				_rock.gift_chance = 1.1
				_rock.fall_speed = 0.0          # 悬停, 排除自然落地干扰
				game.enemies_node.add_child(_rock)
				_next(19, 5)
		19:
			if _due():
				_rock.kill()
				_next(20, 10)
		20:
			if _due():
				check(p.lives == _lives0 + 1, "击碎滚石掉 1UP (%d→%d)" % [_lives0, p.lives])
				_next(99, 1)
		99:
			if _due():
				print("=== 官方对齐八件套验收结束: %d 失败 ===" % fails.size())
				for f in fails:
					print("  失败项: ", f)
				get_tree().quit(1 if fails.size() > 0 else 0)
