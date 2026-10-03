class_name AlienPod extends Enemy
## 异形卵: 静止脉动, 玩家接近时孵化出小兵 (巢穴关专属)

const SHEET_A := preload("res://assets/sprites/alien_pod_0.png")
const SHEET_B := preload("res://assets/sprites/alien_pod_1.png")

var _spawn_cd := 3.0
var _pulse := 0.0

func _ready() -> void:
	add_to_group("enemies")
	hp = 3
	score_val = 300
	make_sprite(SHEET_A, 0, 1, 1)
	make_body_shape(18, 22, -11)
	_spawn_cd = 3.0 + randf() * 2.0

func _physics_process(delta: float) -> void:
	_pulse += delta
	# 脉动动画
	_sprite.texture = SHEET_A if fmod(_pulse, 0.8) < 0.4 else SHEET_B
	var g := get_tree().get_first_node_in_group("game")
	if g == null:
		return
	var pl: Node2D = g.nearest_player(position)
	if pl == null:
		return
	var dist := position.distance_to(pl.position)
	# 玩家接近 → 孵化小兵
	if dist < 240.0 and not pl.dead:
		_spawn_cd -= delta
		if _spawn_cd <= 0.0:
			_spawn_cd = 6.0 + randf() * 3.0
			_hatch()

func _hatch() -> void:
	var e := EnemyRunner.new()
	e.position = position + Vector2(0, 4)
	e.add_to_group("pod_spawned")
	get_parent().add_child(e)
	Fx.make(get_parent(), position + Vector2(0, -6), "spark")
	Boot.play_sfx("sfx_item", -10.0)

func kill() -> void:
	died.emit(score_val)
	# 破裂: 双重爆炸
	Fx.make(get_parent(), position + Vector2(0, -8), "boom")
	Fx.make(get_parent(), position + Vector2(6, -2), "boom", 0.7)
	Boot.play_sfx("sfx_explode")
	queue_free()
