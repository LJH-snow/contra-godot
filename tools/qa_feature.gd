extends Node
## QA 功能验证: 桥头加特林 mini-boss (生成/掉箱/入分), 全过 exit 0

var game: Node2D
var fails: Array[String] = []
var step := 0
var _wait := 0

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
					Boot.score = 0
					g.damage(99, Vector2.RIGHT)     # 一发击杀
				_next(3, 10)
		3:
			if _due():
				check(_gatling() == null, "击杀后已移除")
				check(Boot.score == 1000, "击杀入分 1000 (score=%d)" % Boot.score)
				var dropped := false
				for it in game.items_node.get_children():
					dropped = true
				check(dropped, "击落掉落武器箱")
				print("=== 加特林验证结束: %d 失败 ===" % fails.size())
				for f in fails:
					print("  失败项: ", f)
				get_tree().quit(1 if fails.size() > 0 else 0)
