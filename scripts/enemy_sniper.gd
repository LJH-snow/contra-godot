class_name EnemySniper extends Enemy
## 狙击手: 固定守卫, 三向瞄准 (水平/斜上/竖直), 玩家接近后周期开火

const SHEET := preload("res://assets/sprites/enemies.png")

var fire_int := 1.7
var _t := 0.6
var _angle := 0.0

func _ready() -> void:
	add_to_group("enemies")
	hp = 2
	score_val = GameData.SCORE_SNIPER
	make_sprite(SHEET, 6, 6, 3)
	_sprite.frame = 6 + _angle_index()
	make_body_shape(11, 24, -12)

func _angle_index() -> int:
	if _angle <= -2.2:
		return 2
	elif _angle < -0.5:
		return 1
	return 0
# 行1(帧6..): 横射6 斜上7 竖上8

func aim_angle(pl: Node2D) -> float:
	var v := pl.global_position + Vector2(0, -14) - (global_position + Vector2(0, -18))
	if absf(v.x) < 26.0 and v.y < 0.0:
		return -PI / 2
	return v.angle()

func _physics_process(delta: float) -> void:
	var g := get_tree().get_first_node_in_group("game")
	if g == null:
		return
	var pl: Node2D = g.nearest_player(global_position)
	if pl == null:
		return
	var dx: float = pl.global_position.x - global_position.x
	_sprite.flip_h = dx < 0
	if absf(dx) < 300.0:
		_t -= delta
		if _t < fire_int - 0.25:
			_angle = aim_angle(pl)
			_sprite.frame = 6 + _angle_index()
		if _t <= 0.0:
			_t = fire_int * (0.85 + randf() * 0.3)
			_fire()
	if position.x < g.cam_x - 90.0:
		queue_free()

func _fire() -> void:
	var g := get_tree().get_first_node_in_group("game")
	if g == null:
		return
	var pl: Node2D = g.nearest_player(global_position)
	if pl == null:
		return
	var d := Vector2.RIGHT.rotated(_angle)
	if _sprite.flip_h:                         # 朝左: 直接取玩家方向
		d = (pl.global_position + Vector2(0, -14) - (global_position + Vector2(0, -18))).normalized()
	var eb := EBullet.new()
	g.enemies_node.add_child(eb)
	eb.setup(global_position + Vector2(0, -18) + d * 12.0, d,
		150.0 * GameData.fire_scale(Boot.loop_count))
	Boot.play_sfx("sfx_clang", -6.0)
