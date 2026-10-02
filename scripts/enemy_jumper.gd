class_name EnemyJumper extends EnemyRunner
## 跳兵: 周期高跳逼近, 落点贴近玩家 (官方基地关敌兵之一)

var _hop_t := 0.7

func _ready() -> void:
	super()
	add_to_group("jumper")
	score_val = 200
	_hop_t = 0.5 + randf() * 0.7
	_sprite.self_modulate = Color(0.72, 1.0, 0.72)   # 淡绿标识

func _physics_process(delta: float) -> void:
	_hop_t -= delta
	if _hop_t <= 0.0 and is_on_floor():
		_hop_t = 0.85 + randf() * 0.55
		velocity.y = -305.0
	super(delta)
