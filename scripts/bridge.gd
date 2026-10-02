class_name Bridge extends Node2D
## 吊桥: 玩家踏上后逐段爆炸(逐格禁用碰撞)

signal segment_gone(i: int)

var segs: Array[StaticBody2D] = []
var _lit := -1
var _t := 0.0
var exploding := false
const SEG_W := 16.0

func build(x0: float, y: float, n: int) -> void:
	position = Vector2(x0, y)
	for i in range(n):
		var b := StaticBody2D.new()
		b.collision_layer = GameData.L_WORLD
		var s := Sprite2D.new()
		s.texture = preload("res://assets/sprites/tile_bridge.png")
		s.centered = false
		s.position = Vector2(-8, -8)      # 桥板抬到水线上方, 不再视觉半沉
		b.add_child(s)
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(16, 6)
		cs.shape = sh
		b.add_child(cs)
		b.position = Vector2(i * SEG_W, 0)
		add_child(b)
		segs.append(b)

func _physics_process(delta: float) -> void:
	if exploding:
		_t -= delta
		if _t <= 0.0:
			_t = 0.22
			_pop_next()
		return
	# 检查玩家是否踏上桥
	var pl := get_tree().get_first_node_in_group("player")
	if pl == null:
		return
	var lx: float = pl.global_position.x - position.x
	var i := int(lx / SEG_W)
	if i >= 0 and i < segs.size():
		var dy: float = pl.global_position.y - position.y
		if dy > -14.0 and dy < 14.0:
			exploding = true
			_t = 0.55

func _pop_next() -> void:
	_lit += 1
	if _lit >= segs.size():
		exploding = false
		return
	var b := segs[_lit]
	if b == null:
		return
	Fx.make(get_parent(), b.global_position + Vector2(0, -2), "boom")
	Boot.play_sfx("sfx_explode", -4.0)
	for cs in b.get_children():
		if cs is CollisionShape2D:
			cs.set_deferred("disabled", true)
		var s := b.get_child(0) as Sprite2D
		if s != null:
			s.visible = false
	segment_gone.emit(_lit)
