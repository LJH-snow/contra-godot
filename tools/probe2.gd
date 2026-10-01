extends Node
## 探针2: 复现测试死亡序列, 每10tick记录玩家状态

var game: Node2D
var t := 0
var killed := false

func _ready() -> void:
	var gs: PackedScene = load("res://scenes/main.tscn")
	game = gs.instantiate()
	add_child(game)

func _physics_process(_d: float) -> void:
	t += 1
	if t == 120:
		game.player.pickup(GameData.W.S)
		game.player.pickup(GameData.W.B)
	if t == 180:
		game.player.shield_t = 0.0
		game.player.invuln_t = 0.0
		game.player.hurt(null)
		killed = true
		print("t=180 已执行hurt")
	if killed and t % 10 == 0:
		var p = game.player
		print("t=%d dead=%s lives=%d pos=%v vy=%.0f respawn_t=%.2f" % [
			t, p.dead, p.lives, p.position, p.velocity.y, game._respawn_t])
	if t >= 340:
		get_tree().quit(0)
