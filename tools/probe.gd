extends Node
## 最小探针: 只等待, 每60tick打印玩家状态, 验证物理是否持续运行

var game: Node2D
var t := 0

func _ready() -> void:
	var gs: PackedScene = load("res://scenes/main.tscn")
	game = gs.instantiate()
	add_child(game)

func _physics_process(_d: float) -> void:
	t += 1
	if t % 60 == 0:
		var p = game.player
		print("tick=%d invuln=%.2f pos=%v onground=%s enemies=%d bullets=%d" % [
			t, p.invuln_t, p.position, p.on_ground,
			get_tree().get_nodes_in_group("enemies").size(),
			game.bullets_node.get_child_count()])
	if t >= 600:
		get_tree().quit(0)
