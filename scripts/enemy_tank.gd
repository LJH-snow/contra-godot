class_name EnemyTank extends Enemy
## 碾压坦克 (mini-boss): 从右侧驶入, 缓慢推进, 周期直射炮弹, 击毁掉武器箱
## 由 director.gd 在长平地段 (炮塔区之后) 生成, 自包含设计不侵入 game.gd

const SHEET := preload("res://assets/sprites/enemy_tank.png")
const FALL_LINE := 252.0

var _t := 1.4
var _drive := 0.0

func _ready() -> void:
	add_to_group("enemies")
	hp = 20 + (Boot.loop_count - 1) * 6
	score_val = 2000
	make_sprite(SHEET, 0, 1, 1)
	make_body_shape(70, 28, -14)
	_sprite.offset.y = -8                             # 履带贴地 (匹配敌人 16px 沉降惯例)
	_drive = 0.0
	z_index = 5

func _physics_process(delta: float) -> void:
	var pl := get_tree().get_first_node_in_group("player")
	var g := get_tree().get_first_node_in_group("game")
	velocity.y = minf(velocity.y + 900.0 * delta, 420.0)
	# 履带推进: 缓慢逼近到 110px 距离后停下开火
	if pl != null:
		var dist: float = global_position.x - pl.global_position.x
		if dist > 110.0:
			velocity.x = -34.0
			_drive += delta
		else:
			velocity.x = 0.0
			_t -= delta
			if _t <= 0.0:
				_t = 2.6 * (0.9 + randf() * 0.3)
				_fire(pl)
	else:
		velocity.x = 0.0
	move_and_slide()
	# 颠簸抖动 (履带行进感)
	if _sprite != null and absf(velocity.x) > 1.0:
		_sprite.offset.y = -9.0 if int(_drive * 12.0) % 2 == 0 else -8.0
	# 坠入水面: 自毁
	if position.y > FALL_LINE:
		if g != null and not g.has_floor(position.x, position.y):
			Fx.make(get_parent(), Vector2(position.x, GameData.GROUND_Y + 6.0), "splash")
		died.emit(score_val)
		queue_free()
		return

func _fire(pl: Node2D) -> void:
	var g := get_tree().get_first_node_in_group("game")
	if g == null:
		return
	var d := (pl.global_position + Vector2(0, -12) - (global_position + Vector2(0, -14))).normalized()
	for i in range(2):                                   # 双联炮: 两发小间隔
		var eb := EBullet.new()
		g.enemies_node.add_child(eb)
		eb.setup(global_position + Vector2(0, -14), d, 170.0 + i * 30.0)
	Boot.play_sfx("sfx_clang", 0.0)

func kill() -> void:
	died.emit(score_val)
	Fx.make(get_parent(), position + Vector2(0, -10), "boom_big")
	Fx.make(get_parent(), position + Vector2(-20, 4), "boom")
	Fx.make(get_parent(), position + Vector2(20, 4), "boom")
	Boot.play_sfx("sfx_explode_big")
	var g := get_tree().get_first_node_in_group("game")
	if g != null:
		g.spawn_item(position + Vector2(0, -20))       # 击毁奖励: 武器箱
	queue_free()
