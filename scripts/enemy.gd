class_name Enemy extends CharacterBody2D
## 敌人基类: 受击/死亡/闪烁

signal died(score: int)

var hp := 1
var score_val := 100
var _flash := 0.0
var _sprite: Sprite2D

func _init() -> void:
	collision_layer = GameData.L_ENEMY
	collision_mask = GameData.L_WORLD | GameData.L_PLATFORM

func damage(amt: int, _dir: Vector2) -> void:
	hp -= amt
	_flash = 0.08
	if hp <= 0:
		kill()

func kill() -> void:
	died.emit(score_val)
	Fx.make(get_parent(), position + Vector2(0, -12), "boom")
	Boot.play_sfx("sfx_explode")
	queue_free()

func _process(delta: float) -> void:
	if _sprite == null:
		return
	if _flash > 0.0:
		_flash -= delta
		_sprite.modulate = Color(6, 6, 6)
	else:
		_sprite.modulate = Color(1, 1, 1)

func make_sprite(sheet: Texture2D, frame: int, hf: int, vf: int) -> Sprite2D:
	_sprite = Sprite2D.new()
	_sprite.texture = sheet
	_sprite.hframes = hf
	_sprite.vframes = vf
	_sprite.frame = frame
	add_child(_sprite)
	return _sprite

func make_body_shape(w: float, h: float, oy: float) -> void:
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(w, h)
	cs.shape = sh
	cs.position = Vector2(0, oy)
	add_child(cs)
