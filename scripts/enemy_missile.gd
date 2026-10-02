class_name EnemyMissile extends Enemy
## 空袭追踪导弹: 从空中俯冲追踪玩家, 撞地爆炸, 可被击落

const SHEET := preload("res://assets/sprites/enemy_missile.png")

signal impacted

var dir := Vector2.DOWN
var speed := 190.0
var _life := 5.0
var _spent := false

func setup(spawn: Vector2, target: Vector2) -> void:
	position = spawn
	dir = (target + Vector2(0, -12) - spawn).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("air_missile")
	hp = 1
	score_val = 150
	make_sprite(SHEET, 0, 1, 1)
	make_body_shape(8, 16, 0)
	_sprite.rotation = dir.angle() + PI / 2.0
	z_index = 6

func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	var g := get_tree().get_first_node_in_group("game")
	if g == null:
		queue_free()
		return
	var target: Player = g.nearest_player(position)
	if target != null:
		var desired := (target.position + Vector2(0, -12) - position).normalized()
		var turn := clampf(dir.angle_to(desired), -2.2 * delta, 2.2 * delta)
		dir = dir.rotated(turn).normalized()
	_sprite.rotation = dir.angle() + PI / 2.0
	var collision := move_and_collide(dir * speed * delta)
	if collision != null:
		_impact()
		return
	if position.y >= GameData.GROUND_Y and not g.has_floor(position.x, position.y):
		_impact()
		return
	if position.x < g.cam_x - 70.0 or position.x > g.cam_x + 390.0 \
			or position.y < -80.0 or position.y > 300.0:
		queue_free()

func kill() -> void:
	if _spent:
		return
	_spent = true
	died.emit(score_val)
	Fx.make(get_parent(), position, "boom_big")
	Boot.play_sfx("sfx_explode_big")
	queue_free()

func _impact() -> void:
	if _spent:
		return
	_spent = true
	impacted.emit()
	var g := get_tree().get_first_node_in_group("game")
	var floor_y: float = g.floor_y_at(position.x, position.y) if g != null else INF
	if floor_y != INF:
		Fx.make(get_parent(), Vector2(position.x, floor_y - 4.0), "boom_big")
		Boot.play_sfx("sfx_explode_big")
	else:
		Fx.make(get_parent(), Vector2(position.x, GameData.GROUND_Y + 2.0), "splash")
		Boot.play_sfx("sfx_splash", -3.0)
	queue_free()
