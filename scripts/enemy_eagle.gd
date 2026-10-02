class_name EnemyEagle extends Enemy
## 震天鹰编队: 三鹰同行, 击落中间金色者 = 清屏 + 1 命 (官方雪原彩蛋)

const SHEET := preload("res://assets/sprites/enemies.png")

var is_middle := false
var _wiping := false                       # 防重入: 清屏时勿再对自己 kill()
var t := 0.0
var _base_y := 70.0
var _amp := 16.0
var _freq := 3.0

func setup_formation(pos: Vector2, middle: bool, base_y: float) -> void:
	position = pos
	is_middle = middle
	_base_y = base_y

func _ready() -> void:
	add_to_group("enemies")
	hp = 1
	score_val = 500
	make_sprite(SHEET, 12, 6, 3)
	make_body_shape(14, 12, 0)
	z_index = 5
	_sprite.self_modulate = Color(1.0, 0.85, 0.3) if is_middle else Color(0.8, 0.8, 0.9)

func _physics_process(delta: float) -> void:
	t += delta
	position.x += 95.0 * delta
	position.y = _base_y + sin(t * _freq) * _amp
	_sprite.frame = 12 + (int(t * 10.0) % 2)
	var g := get_tree().get_first_node_in_group("game")
	if position.x > ((g.cam_x + 440.0) if g != null else 400.0):
		queue_free()

func kill() -> void:
	if _wiping:
		return
	_wiping = true
	var g := get_tree().get_first_node_in_group("game")
	if is_middle and g != null:
		died.emit(1000)
		g.eagle_wipe()                        # 金鹰闪击: 全屏清敌 (含侧翼)
		for p in g.players:
			p.lives += 1                      # +1 命
		g.hud.call("flash_message", "oneup", 1.4)
		Boot.play_sfx("sfx_powerup", -2.0)
	else:
		died.emit(score_val)
		if g != null:
			g.spawn_item(global_position)     # 侧翼掉武器箱
	Fx.make(get_parent(), position, "boom")
	Boot.play_sfx("sfx_explode")
	queue_free()
