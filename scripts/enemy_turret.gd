class_name EnemyTurret extends Enemy
## 固定炮塔: 8 向旋转炮管, 追踪玩家后连射 3 发

const SHEET := preload("res://assets/sprites/turret.png")

var fire_int := 2.1
var _t := 1.0
var _burst := 0
var _burst_t := 0.0
var _aim := 4

func _ready() -> void:
	add_to_group("enemies")
	hp = 4
	score_val = GameData.SCORE_TURRET
	_sprite = make_sprite(SHEET, 0, 9, 1)
	_sprite.frame = 0
	make_body_shape(13, 13, -8)
	_t = 0.8 + randf() * 1.2

func _physics_process(delta: float) -> void:
	var pl := get_tree().get_first_node_in_group("player")
	if pl == null:
		return
	var to_p: Vector2 = pl.global_position + Vector2(0, -12) - global_position
	var want := wrapi(roundi(to_p.angle() / (PI / 4)), 0, 8)
	if absf(to_p.x) < 260.0:
		_aim = want
		_sprite.frame = 1 + _aim
		if _burst > 0:
			_burst_t -= delta
			if _burst_t <= 0.0:
				_burst -= 1
				_burst_t = 0.28
				_fire()
		else:
			_t -= delta
			if _t <= 0.0:
				_t = fire_int * (0.85 + randf() * 0.4)
				_burst = 3
				_burst_t = 0.0

func _fire() -> void:
	var g := get_tree().get_first_node_in_group("game")
	if g == null:
		return
	var d := Vector2.RIGHT.rotated(_aim * PI / 4)
	var eb := EBullet.new()
	g.enemies_node.add_child(eb)
	eb.setup(global_position + Vector2(0, -8) + d * 10.0, d,
		145.0 * GameData.fire_scale(Boot.loop_count))
	Boot.play_sfx("sfx_clang", -4.0)

func kill() -> void:
	died.emit(score_val)
	Fx.make(get_parent(), position + Vector2(0, -8), "boom_big")
	Boot.play_sfx("sfx_explode")
	queue_free()
