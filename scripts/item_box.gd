class_name ItemBox extends Area2D
## 击落胶囊后掉落的红色鹰徽箱: 落地静止, 玩家拾取获得武器

const SHEET := preload("res://assets/sprites/items.png")

var wtype := GameData.W.M
var vy := 0.0
var _sprite: Sprite2D

func setup(pos: Vector2, w: int) -> void:
	position = pos
	wtype = w

func _ready() -> void:
	collision_layer = GameData.L_ITEM
	collision_mask = GameData.L_WORLD | GameData.L_PLATFORM | GameData.L_PLAYER
	_sprite = Sprite2D.new()
	_sprite.texture = SHEET
	_sprite.hframes = 8
	_sprite.frame = 6 if wtype == GameData.W.EAGLE else wtype
	add_child(_sprite)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(16, 12)
	cs.shape = sh
	add_child(cs)
	body_entered.connect(_on_body)

func _physics_process(delta: float) -> void:
	if vy != 0.0:
		vy = minf(vy + 620.0 * delta, 300.0)
		position.y += vy * delta
		var g := get_tree().get_first_node_in_group("game")
		if g != null:
			var fy: float = g.floor_y_at(position.x, position.y)
			if fy != INF and position.y >= fy:
				position.y = fy
				vy = 0.0
		if position.y > 280.0:
			queue_free()

func _on_body(b: Node) -> void:
	if b is StaticBody2D:
		return
	if b.has_method("pickup"):
		b.pickup(wtype)
		Boot.play_sfx("sfx_item")
		queue_free()
