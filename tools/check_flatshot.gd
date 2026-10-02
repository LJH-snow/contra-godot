extends Node
## 针对验收: Boss 核心必须能被站立平射命中 (官方设计: 弱点在平射带内)

var game: Node2D
var step := 0
var _wait := 0
var _hp0 := -1
var _shot := false

func _ready() -> void:
	print("=== 平射命中验收开始 ===")
	Boot.player_count = 1
	Boot.level = 1
	var gs: PackedScene = load("res://scenes/main.tscn")
	game = gs.instantiate()
	add_child(game)
	_next(0, 5)

func _fail(msg: String) -> void:
	print("FAIL: " + msg)
	get_tree().quit(1)

func _due() -> bool:
	_wait -= 1
	return _wait <= 0

func _next(n: int, wait: int) -> void:
	step = n
	_wait = wait

func _physics_process(_delta: float) -> void:
	if not _due():
		return
	match step:
		0:
			if game.players.is_empty():
				_fail("玩家未生成")
				return
			var p: Player = game.players[0]
			# 站到 Boss 墙前, 触发 Boss 战
			p.position = Vector2(3260.0, 200.0)
			_next(1, 200)                     # 越过 2s intro 后 Boss 触发
		1:
			if not game.boss_active:
				_fail("Boss战未触发")
				return
			# 等待闸门开启 (开门即核心暴露)
			_next(2, 10)
		2:
			var core: BossCore = game.boss_core
			if core == null:
				_fail("核心不存在")
				return
			if not core.open:
				_next(2, 10)
				return
			_hp0 = core.hp
			# 站立平射: 模拟玩家原地开一枪 (aim_dir 水平, 站立不动)
			var p: Player = game.players[0]
			p.position = Vector2(3290.0, 200.0)
			var b := Bullet.new()
			b.setup(p.muzzle_pos(Vector2(p.facing, 0)), Vector2(p.facing, 0), GameData.W.NORMAL)
			game.bullets_node.add_child(b)
			_shot = true
			_next(3, 20)
		3:
			var core: BossCore = game.boss_core
			if core == null or not is_instance_valid(core):
				_fail("核心被一发击毁? 血量异常")
				return
			if core.hp < _hp0:
				print("PASS: 站立平射命中核心 (hp %d -> %d)" % [_hp0, core.hp])
				print("=== 平射命中验收结束 ===")
				get_tree().quit(0)
			else:
				_fail("站立平射未命中核心 (弹道被墙挡住或高度不合)")
