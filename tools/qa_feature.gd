extends Node
## QA 功能验证: 桥头加特林 mini-boss / 碾压坦克 / 空袭导弹 (生成/入分/爆炸), 全过 exit 0

var game: Node2D
var fails: Array[String] = []
var step := 0
var _wait := 0
var _missile_impacted := false
var _test_missile: EnemyMissile
var _impact_missile: EnemyMissile
var _missile_dir_before := Vector2.ZERO

func _ready() -> void:
	print("=== 加特林 mini-boss 验证开始 ===")
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

func _gatling() -> Node:
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is EnemyGatling:
			return e
	return null

## 清零分数并重置 FxDirector 连击, 避免连击奖励污染精确分数断言
func _reset_score() -> void:
	Boot.score = 0
	var fx := get_node_or_null("/root/Boot/FxDirector")
	if fx != null:
		fx.set("_combo", 0)
		fx.set("_combo_t", 0.0)

func _physics_process(_d: float) -> void:
	match step:
		0:
			if _due():
				game.player.shield_t = 999.0        # 免死
				game.player.position.x = 1400.0     # 越过触发线
				_next(1, 40)
		1:
			if _due():
				check(_gatling() != null, "接近吊桥时加特林生成")
				check(Boot.score == 0, "生成本身不入分")
				_next(2, 30)
		2:
			if _due():
				var g = _gatling()
				check(g != null and g.hp > 0, "加特林存活 (hp=%s)" % (str(g.hp) if g else "-"))
				if g != null:
					_reset_score()
					g.damage(99, Vector2.RIGHT)     # 一发击杀
					check(Boot.score == 1000, "击杀入分 1000 (score=%d)" % Boot.score)
				_next(3, 10)
		3:
			if _due():
				check(_gatling() == null, "击杀后已移除")
				var dropped := false
				for it in game.items_node.get_children():
					dropped = true
				check(dropped, "击落掉落武器箱")
				game.player.position.x = 2400.0     # 长平地段: 触发坦克
				_next(4, 60)
		4:
			if _due():
				var tank: Node = null
				for e in get_tree().get_nodes_in_group("enemies"):
					if e is EnemyTank:
						tank = e
				check(tank != null, "碾压坦克生成")
				if tank != null:
					_reset_score()
					tank.damage(99, Vector2.RIGHT)
					check(Boot.score == 2000, "坦克入分 2000 (score=%d)" % Boot.score)
				_next(5, 10)
		5:
			if _due():
				_reset_score()
				game.player.position = Vector2(2520.0, GameData.GROUND_Y)
				_next(6, 60)
		6:
			if _due():
				# 空袭导弹已按用户要求移除: 桥后区域不应再出现任何导弹
				var missiles := get_tree().get_nodes_in_group("air_missile")
				check(missiles.is_empty(), "空袭已移除: 桥后无导弹 (实际%d)" % missiles.size())
				print("=== mini-boss 与空袭验证结束: %d 失败 ===" % fails.size())
				for f in fails:
					print("  失败项: ", f)
				get_tree().quit(1 if fails.size() > 0 else 0)
