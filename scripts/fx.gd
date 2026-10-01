class_name Fx extends Node2D
## 通用动画特效: 爆炸 / 枪口焰 / 水花 / 火花

const SHEET := preload("res://assets/sprites/fx.png")

var _frames: Array[int] = [0]
var _t := 0.0
var _fps := 14.0
var _sprite: Sprite2D

static func make(parent: Node, pos: Vector2, kind: String, scl := 1.0, rot := 0.0) -> Fx:
	var fx := Fx.new()
	match kind:
		"boom": fx._setup([0, 1, 2, 3, 4, 5], 14.0)
		"boom_big": fx._setup([0, 1, 2, 3, 4, 5], 10.0)
		"muzzle": fx._setup([6, 7], 24.0)
		"splash": fx._setup([8, 9, 10], 10.0)
		"spark": fx._setup([12, 13, 14], 18.0)
	if kind == "boom_big":
		scl *= 2.0
	parent.add_child(fx)
	fx.position = pos
	fx.rotation = rot
	fx.scale = Vector2(scl, scl)
	return fx

func _setup(frames: Array[int], fps: float) -> void:
	_frames = frames
	_fps = fps

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = SHEET
	_sprite.hframes = 6
	_sprite.vframes = 3
	_sprite.frame = _frames[0]
	add_child(_sprite)

func _process(delta: float) -> void:
	_t += delta
	var i := int(_t * _fps)
	if i >= _frames.size():
		queue_free()
		return
	_sprite.frame = _frames[i]
