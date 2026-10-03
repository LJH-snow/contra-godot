class_name EBullet extends Area2D
## 敌方子弹 (碰到玩家即致命, 由玩家的受击区检测)

const SHEET := preload("res://assets/sprites/bullets.png")

var dir := Vector2.LEFT
var speed := 130.0
var t := 0.0
var grav := 0.0                        # >0 = 手雷抛物线
var vel := Vector2.ZERO

func setup(pos: Vector2, d: Vector2, spd: float) -> void:
	position = pos
	dir = d
	speed = spd

## 手雷: 给定初速度, 重力下坠, 落地爆炸
func setup_grenade(pos: Vector2, v: Vector2) -> void:
	position = pos
	vel = v
	grav = 620.0

func _ready() -> void:
	collision_layer = GameData.L_EBULLET
	collision_mask = 0
	var s := Sprite2D.new()
	s.texture = SHEET
	s.hframes = 6
	s.frame = 3
	if grav > 0.0:
		s.scale = Vector2(1.3, 1.3)
		s.modulate = Color(0.75, 0.85, 0.6)   # 土黄手雷
	add_child(s)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(4, 4)               # 比弹头贴图略小: 擦过不算命中
	cs.shape = sh
	add_child(cs)

func _physics_process(delta: float) -> void:
	t += delta
	if grav > 0.0:
		vel.y += grav * delta
		position += vel * delta
		var g := get_tree().get_first_node_in_group("game")
		# 落地(或入水)即爆炸
		if g != null and position.y > g.L_GROUND_Y - 2.0:
			var fy: float = g.floor_y_at(position.x, position.y)
			if fy != INF and position.y >= fy - 4.0:
				Fx.make(get_parent(), Vector2(position.x, fy - 6.0), "boom", 1.2)
				Boot.play_sfx("sfx_explode", -4.0)
				queue_free()
				return
			if position.y > g.L_GROUND_Y + 10.0:   # 落水
				Fx.make(get_parent(), Vector2(position.x, g.L_GROUND_Y + 4.0), "splash")
				Boot.play_sfx("sfx_splash", -3.0)
				queue_free()
				return
	else:
		position += dir * speed * delta
	var g2 := get_tree().get_first_node_in_group("game")
	if t > 6.0 or g2 == null:
		queue_free()
		return
	if g2.L_VERTICAL:
		if position.y < g2.cam_y - 80.0 or position.y > g2.cam_y + 320.0 \
				or position.x < -40.0 or position.x > g2.L_W + 40.0:
			queue_free()
	elif position.x < g2.cam_x - 70.0 or position.x > g2.cam_x + 390.0 \
			or position.y < -80.0 or position.y > 300.0:
		queue_free()
