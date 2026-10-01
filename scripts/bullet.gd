class_name Bullet extends Area2D
## 玩家子弹: 步枪/机枪/散弹/雷射(穿透)/火球(螺旋)

const SHEET := preload("res://assets/sprites/bullets.png")
const LASER_TEX := preload("res://assets/sprites/laser.png")

var dir := Vector2.RIGHT
var speed := 300.0
var dmg := 1
var wtype := 0
var pierce := false
var t := 0.0
var _origin := Vector2.ZERO
var _hit: Array = []
var _dead := false
var _sprite: Sprite2D

func setup(pos: Vector2, d: Vector2, w: int) -> void:
	position = pos
	dir = d
	wtype = w
	_origin = pos

func _ready() -> void:
	collision_layer = GameData.L_PBULLET
	collision_mask = GameData.L_ENEMY
	_sprite = Sprite2D.new()
	add_child(_sprite)
	match wtype:
		GameData.W.M:
			speed = 340.0
			_use_sheet(1)
		GameData.W.S:
			speed = 250.0
			_use_sheet(2)
		GameData.W.L:
			speed = 520.0
			dmg = 3
			pierce = true
			_sprite.texture = LASER_TEX
			_sprite.offset = Vector2(12, 0)
		GameData.W.F:
			speed = 150.0
			_use_sheet(4)
		_:
			speed = 300.0
			_use_sheet(0)
	if wtype != GameData.W.L:
		_sprite.offset = Vector2(dir.x * 3.0, dir.y * 3.0)
	_sprite.rotation = dir.angle()
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(10, 10)
	cs.shape = sh
	add_child(cs)
	body_entered.connect(_on_body)

func _use_sheet(frame: int) -> void:
	_sprite.texture = SHEET
	_sprite.hframes = 6
	_sprite.frame = frame

func _physics_process(delta: float) -> void:
	t += delta
	if wtype == GameData.W.F:
		# 火球: 直线前进 + 垂直正弦摆动
		var perp := Vector2(-dir.y, dir.x)
		position = _origin + dir * (speed * t) + perp * (sin(t * 9.0) * 26.0)
	else:
		position += dir * speed * delta
	if t > 1.8:
		queue_free()
		return
	var g := get_tree().get_first_node_in_group("game")
	if g != null and (position.x < g.cam_x - 60.0 or position.x > g.cam_x + 420.0
			or position.y < -60.0 or position.y > 300.0):
		queue_free()

func _on_body(b: Node) -> void:
	if _dead or not b.has_method("damage"):
		return
	if b in _hit:
		return
	_hit.append(b)
	b.damage(dmg, dir)
	if not pierce:
		_die()

func _die() -> void:
	if _dead:
		return
	_dead = true
	queue_free()
