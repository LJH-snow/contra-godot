extends Node
## 第四关(异形巢穴)专项验收: Boot.level=4

var game: Node2D
var fails: Array[String] = []
var step := 0
var _wait := 0
var _frames := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("=== 巢穴关验收开始 ===")
	Boot.level = 4
	Boot.difficulty = 1
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

func _next(n: int, w: int) -> void:
	step = n
	_wait = w

func _physics_process(_d: float) -> void:
	match step:
		0:
			if _due():
				game._intro_t = 0.0
				# 确定性: 清非卵/非Boss敌人 + 冻结生成器
				for e in get_tree().get_nodes_in_group("enemies"):
					if not (e is AlienPod) and not (e is BossCore):
						e.queue_free()
				game._spawn_t = 99999.0
				game._capsule_t = 99999.0
				check(not game.L_VERTICAL, "巢穴为横向卷轴")
				check(game.L_GROUNDS.size() == 4, "巢穴地段 4 段")
				var bg := game.get_node("Background/Sky/SkySprite")
				check(bg.texture.resource_path.ends_with("bg_cave_sky.png"), "洞穴背景已换装")
				check(game.get_node("Background/FarLayer/FarSprite").texture.resource_path.ends_with("bg_cave.png"), "洞壁远景已换装")
				var pods := 0
				for e in get_tree().get_nodes_in_group("enemies"):
					if e is AlienPod:
						pods += 1
				check(pods == 8, "异形卵已布置(%d个)" % pods)
				_next(1, 20)
		1:
			if _due():
				# 孵化测试: 传送玩家到卵旁
				game.player.position = Vector2(590, 170)
				game.player.shield_t = 30.0        # 孵化等待期免死 (护盾不影响孵化)
				_next(2, 340)
		2:
			if _due():
				var hatched := get_tree().get_nodes_in_group("pod_spawned").size()
				check(hatched > 0, "卵孵化出小兵(%d)" % hatched)
				# 心脏 Boss: 血量与配色
				check(game.boss_core.max_hp == 45, "心脏血量 45")
				check(game.boss_core.modulate == Color(1.0, 0.45, 0.6), "心脏配色")
				# 触发 Boss
				game.player.position = Vector2(3200, 170)
				_next(3, 40)
		3:
			if _due():
				check(game.boss_active, "巢穴 Boss 战触发")
				if is_instance_valid(game.boss_core):
					game.boss_core.set_open(true)
					game.boss_core.damage(35, Vector2.RIGHT)   # 打入狂暴 (45血 → 10)
				_next(4, 10)
		4:
			if _due():
				check(is_instance_valid(game.boss_core) and game.boss_core.enraged, "心脏狂暴触发")
				# 击破 → 结局场景
				_next(5, 2)
		5:
			if _due():
				if game.level_done:
					check(true, "巢穴 Boss 被击破")
					Boot.set_meta("lair_check", true)   # 结局场景加载后自行断言并退出
					_next(6, 300)
				elif not is_instance_valid(game.boss_core):
					_wait = 2
				elif _frames > 1200:
					check(false, "Boss 击破超时")
					_next(6, 0)
				else:
					_frames += 1
					game.boss_core.set_open(true)
					var b := Bullet.new()
					b.setup(game.boss_core.position + Vector2(-30, -14), Vector2.RIGHT, GameData.W.NORMAL)
					game.bullets_node.add_child(b)
					_wait = 2
		6:
			if _due():
				# 结局分流: level 4 完成 → ending 场景加载后由结局场景自行断言并退出
				_wait = 30
