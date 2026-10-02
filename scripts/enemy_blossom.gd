class_name EnemyBlossom extends Enemy
## 开花弹兵: 定点原地周期"开花"环形弹幕, 不可击毙 (官方雪原关特色, 只能躲)

const SHEET := preload("res://assets/sprites/enemies.png")

var _t := 1.6
var _pulse := 0.0

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("blossom")
	hp = 999999                              # 不可击毙 (damage 覆盖)
	score_val = 0
	make_sprite(SHEET, 7, 6, 3)              # 开火姿态帧
	make_body_shape(12, 24, -12)
	z_index = 3

func _physics_process(delta: float) -> void:
	_pulse += delta
	_sprite.self_modulate = Color(1.0, 0.62, 0.72) \
		if fmod(_pulse, 1.0) < 0.5 else Color(0.9, 0.45, 0.6)
	var g := get_tree().get_first_node_in_group("game")
	if g == null:
		return
	var pl: Node2D = g.nearest_player(global_position)
	if pl == null:
		return
	_t -= delta
	if _t <= 0.0:
		_t = (2.6 + randf() * 1.2) / maxf(GameData.fire_scale(Boot.loop_count), 0.4)
		_bloom(g)

## 开花: 6 向环形弹幕 (固定角度, 可预判走位)
func _bloom(g: Node) -> void:
	var base := randf() * TAU
	for i in range(6):
		var d := Vector2.RIGHT.rotated(base + TAU * i / 6.0)
		var eb := EBullet.new()
		eb.setup(global_position + Vector2(0, -12) + d * 8.0, d,
			95.0 * GameData.fire_scale(Boot.loop_count))
		g.enemies_node.add_child(eb)
	Boot.play_sfx("sfx_spread", -8.0)

func damage(_amt: int, _dir: Vector2) -> void:
	Boot.play_sfx("sfx_clang", -6.0)         # 子弹被弹开, 毫发无损
