class_name EnemyCapsule extends Enemy
## 飞行胶囊: 载武器道具, 正弦波飞过屏幕, 被击落后掉落道具箱

const SHEET := preload("res://assets/sprites/enemies.png")

var t := 0.0
var _base_y := 70.0
var _amp := 30.0
var _freq := 3.2

func _ready() -> void:
	add_to_group("enemies")
	hp = 1
	score_val = GameData.SCORE_CAPSULE
	_base_y = 56.0 + randf() * 60.0
	_amp = 20.0 + randf() * 18.0
	_freq = 2.4 + randf() * 1.6
	var g := get_tree().get_first_node_in_group("game")
	position = Vector2((g.cam_x - 24.0) if g != null else -24.0, _base_y)
	make_sprite(SHEET, 12, 6, 3)               # 行2: 胶囊帧12/13
	make_body_shape(14, 12, 0)
	z_index = 5

func _physics_process(delta: float) -> void:
	t += delta
	position.x += 105.0 * delta
	position.y = _base_y + sin(t * _freq) * _amp
	_sprite.frame = 12 + (int(t * 10.0) % 2)
	var g := get_tree().get_first_node_in_group("game")
	if position.x > ((g.cam_x + 440.0) if g != null else 400.0):
		queue_free()

func kill() -> void:
	died.emit(score_val)
	var g := get_tree().get_first_node_in_group("game")
	if g != null:
		g.spawn_item(global_position)
	Fx.make(get_parent(), position, "boom")
	Boot.play_sfx("sfx_explode")
	queue_free()
