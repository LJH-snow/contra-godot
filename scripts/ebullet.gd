class_name EBullet extends Area2D
## 敌方子弹 (碰到玩家即致命, 由玩家的受击区检测)

const SHEET := preload("res://assets/sprites/bullets.png")

var dir := Vector2.LEFT
var speed := 130.0
var t := 0.0

func setup(pos: Vector2, d: Vector2, spd: float) -> void:
	position = pos
	dir = d
	speed = spd

func _ready() -> void:
	collision_layer = GameData.L_EBULLET
	collision_mask = 0
	var s := Sprite2D.new()
	s.texture = SHEET
	s.hframes = 6
	s.frame = 3
	add_child(s)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(6, 6)
	cs.shape = sh
	add_child(cs)

func _physics_process(delta: float) -> void:
	t += delta
	position += dir * speed * delta
	var g := get_tree().get_first_node_in_group("game")
	if t > 6.0 or g == null:
		queue_free()
		return
	if g.L_VERTICAL:
		if position.y < g.cam_y - 80.0 or position.y > g.cam_y + 320.0 \
				or position.x < -40.0 or position.x > g.L_W + 40.0:
			queue_free()
	elif position.x < g.cam_x - 70.0 or position.x > g.cam_x + 390.0 \
			or position.y < -80.0 or position.y > 300.0:
		queue_free()
