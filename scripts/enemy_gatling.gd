class_name EnemyGatling extends Enemy
## 桥头加特林机枪堡 (mini-boss): 悬停扫射五向弹, 击落掉武器箱
## 由 director.gd 在玩家接近吊桥时生成, 自包含设计不侵入 game.gd

const SHEET := preload("res://assets/sprites/enemy_gatling.png")

var _t := 1.6
var _spin := 0.0
var _base_y := 0.0

func _ready() -> void:
	add_to_group("enemies")
	hp = 12 + (Boot.loop_count - 1) * 4
	score_val = 1000
	make_sprite(SHEET, 0, 2, 1)
	make_body_shape(18, 18, 0)
	_base_y = position.y
	_t = 1.2 + randf() * 0.8
	z_index = 5

func _physics_process(delta: float) -> void:
	var pl := get_tree().get_first_node_in_group("player")
	var g := get_tree().get_first_node_in_group("game")
	_spin += delta
	_sprite.frame = int(_spin * 10.0) % 2          # 炮管旋转
	# 悬浮: 正弦漂浮 + 与玩家保持 90px 水平距离缓慢逼近
	if pl != null:
		var side := signf(global_position.x - pl.global_position.x)
		var target_x: float = pl.global_position.x + side * 90.0
		position.x = move_toward(position.x, target_x, 20.0 * delta)
	position.y = _base_y + sin(_spin * 1.7) * 14.0
	if pl != null:
		_t -= delta
		if _t <= 0.0:
			_t = 2.2 * (0.9 + randf() * 0.3)
			_fire(pl)
	if g != null and position.x < g.cam_x - 120.0:
		queue_free()

func _fire(pl: Node2D) -> void:
	var g := get_tree().get_first_node_in_group("game")
	if g == null:
		return
	var d := (pl.global_position + Vector2(0, -12) - global_position).normalized()
	for off in [-0.5, -0.25, 0.0, 0.25, 0.5]:
		var eb := EBullet.new()
		g.enemies_node.add_child(eb)
		eb.setup(global_position, d.rotated(off),
			130.0 * GameData.fire_scale(Boot.loop_count))
	Boot.play_sfx("sfx_clang", -3.0)

func kill() -> void:
	died.emit(score_val)
	Fx.make(get_parent(), position, "boom_big")
	Boot.play_sfx("sfx_explode_big")
	var g := get_tree().get_first_node_in_group("game")
	if g != null:
		g.spawn_item(position)                     # 击落奖励: 武器箱
	queue_free()
