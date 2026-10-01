class_name EnemyRunner extends Enemy
## 杂兵: 直线冲锋, 崖边跳跃, 偶尔停步射击

const SHEET := preload("res://assets/sprites/enemies.png")

var run_dir := -1
var run_speed := 62.0
var _anim_t := 0.0
var _fire_t := 1.5
var _stop_t := 0.0

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("runner")
	hp = 1
	score_val = GameData.SCORE_RUNNER
	make_sprite(SHEET, 0, 6, 3)
	make_body_shape(10, 26, -13)
	run_speed = (55.0 + randf() * 28.0) * GameData.speed_scale(Boot.loop_count)
	if randf() < 0.12:
		run_dir = 1
	_sprite.flip_h = run_dir > 0
	_fire_t = 1.2 + randf() * 2.4

func _physics_process(delta: float) -> void:
	var g := get_tree().get_first_node_in_group("game")
	var pl := get_tree().get_first_node_in_group("player")
	velocity.y = minf(velocity.y + 800.0 * delta, 420.0)
	if _stop_t > 0.0:
		_stop_t -= delta
		velocity.x = 0.0
		if _stop_t <= 0.0:
			_shoot()
	else:
		velocity.x = run_dir * run_speed
	if is_on_floor() and g != null:
		if not g.has_floor(position.x + run_dir * 14.0, position.y):
			if randf() < 0.65:
				velocity.y = -245.0
	move_and_slide()
	_anim_t += delta
	if _stop_t <= 0.0:
		_sprite.frame = int(_anim_t * 10.0) % 4
	# 朝向玩家停步开火
	if pl != null and _stop_t <= 0.0 and is_on_floor():
		_fire_t -= delta
		if _fire_t <= 0.0:
			var dx: float = pl.global_position.x - global_position.x
			var dy: float = pl.global_position.y - global_position.y
			if absf(dx) < 230.0 and absf(dy) < 42.0:
				_stop_t = 0.32
			else:
				_fire_t = 0.9
	# 出屏 / 落水
	if position.y > 270.0:
		if g != null and not g.has_floor(position.x, position.y):
			Fx.make(get_parent(), Vector2(position.x, GameData.GROUND_Y + 6.0), "splash")
		queue_free()
		return
	if g != null and (position.x < g.cam_x - 100.0 or position.x > g.cam_x + 440.0):
		queue_free()

func _shoot() -> void:
	_fire_t = 1.4 + randf() * 2.0
	var pl := get_tree().get_first_node_in_group("player")
	if pl == null:
		return
	var d := signf(pl.global_position.x - global_position.x)
	if d == 0.0:
		d = -1.0
	var g := get_tree().get_first_node_in_group("game")
	if g == null:
		return
	var eb := EBullet.new()
	g.enemies_node.add_child(eb)
	eb.setup(global_position + Vector2(d * 12.0, -15.0), Vector2(d, 0.0),
		118.0 * GameData.fire_scale(Boot.loop_count))
	Boot.play_sfx("sfx_clang", -8.0)
