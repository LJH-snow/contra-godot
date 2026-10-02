extends Node
## 探针: 复现 test_runner 的桥→Boss 流程, 观察玩家/相机状态

var game: Node2D
var step := 0
var _wait := 0

func _ready() -> void:
	Boot.player_count = 2
	Boot.level = 1
	var gs: PackedScene = load("res://scenes/main.tscn")
	game = gs.instantiate()
	add_child(game)
	_next(0, 20)

func _next(n: int, wait: int) -> void:
	step = n
	_wait = wait

func _due() -> bool:
	_wait -= 1
	return _wait <= 0

func _dump(tag: String) -> void:
	for i in range(game.players.size()):
		var p: Player = game.players[i]
		print("  [%s] P%d pos=%s dead=%s swim=%s sub=%s lives=%d" % [tag, i + 1, p.position, p.dead, p.swim, p.submerged, p.lives])
	print("  [%s] cam_x=%.0f boss_active=%s intro_t=%.1f spawn_t=%.0f" % [tag, game.cam_x, game.boss_active, game._intro_t, game._spawn_t])

func _physics_process(_d: float) -> void:
	if not _due():
		return
	match step:
		0:
			_dump("初始")
			game.player.position = Vector2(game.bridge.position.x + 8, game.bridge.position.y - 6)
			_next(1, 100)
		1:
			_dump("桥断后")
			game.player.position = Vector2(3300, GameData.GROUND_Y - 30)
			game.player.velocity = Vector2.ZERO
			if game.player.dead:
				game.player.respawn(game.player.position)
			_next(2, 40)
		2:
			_dump("传送40帧后")
			get_tree().quit(0)
